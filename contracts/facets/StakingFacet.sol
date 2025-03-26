// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import { LibAppStorage } from "../libraries/AppStorage.sol";

contract Staking {
    LibAppStorage.AppStorage internal s;

    error UnsupportedToken();
    error StakeMoreThan0();
    error StakeNotFound();
    error NoRewardsToClaim();
    error Erc20DoNotUseTokenId();
    error Erc721CanOnlyStake1Token();

    uint256 private constant PRECISION = 1e18;
    uint256 private constant REWARDS_DURATION = 365 days;

    event TokenStaked(
        address indexed user, 
        address tokenAddress, 
        uint256 tokenId, 
        LibAppStorage.StakeType stakeType, 
        uint256 amount
    );
    event TokenUnstaked(
        address indexed user, 
        address tokenAddress, 
        uint256 tokenId, 
        LibAppStorage.StakeType stakeType, 
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 reward);

    constructor() {
        s.rewardRate = 10;
        s.lastUpdateTime = block.timestamp;
        s.owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == s.owner, "Not owner");
        _;
    }

    // Test-only function to add supported tokens
    function addSupportedToken(address token) external onlyOwner {
        s.supportedTokens[token] = true;
    }

    function stake(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount, 
        LibAppStorage.StakeType stakeType
    ) external {
        if (!s.supportedTokens[tokenAddress]) {
            revert UnsupportedToken();
        }
        if (amount <= 0) {
            revert StakeMoreThan0();
        }

        _updateReward(msg.sender);

        _transferTokensIn(tokenAddress, tokenId, amount, stakeType);

        LibAppStorage.StakeInfo memory newStake = LibAppStorage.StakeInfo({
            user: msg.sender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            stakeType: stakeType,
            amount: amount,
            stakeTime: block.timestamp,
            lastClaimTime: block.timestamp
        });

        s.userStakes[msg.sender].push(newStake);
        s.totalStakedByUser[msg.sender] += amount;
        s.totalStakedAmount += amount;

        emit TokenStaked(msg.sender, tokenAddress, tokenId, stakeType, amount);
    }

    function unstake(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount
    ) external {
        _updateReward(msg.sender);

        LibAppStorage.StakeInfo[] storage userStakes = s.userStakes[msg.sender];
        bool found = false;
        uint256 stakeIndex;

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (
                userStakes[i].tokenAddress == tokenAddress &&
                userStakes[i].tokenId == tokenId &&
                userStakes[i].amount >= amount
            ) {
                stakeIndex = i;
                found = true;
                break;
            }
        }

        if (!found) {
            revert StakeNotFound();
        }

        userStakes[stakeIndex].amount -= amount;
        s.totalStakedByUser[msg.sender] -= amount;
        s.totalStakedAmount -= amount;

        if (userStakes[stakeIndex].amount == 0) {
            userStakes[stakeIndex] = userStakes[userStakes.length - 1];
            userStakes.pop();
        }

        _transferTokensOut(tokenAddress, tokenId, amount, userStakes[stakeIndex].stakeType);

        emit TokenUnstaked(msg.sender, tokenAddress, tokenId, userStakes[stakeIndex].stakeType, amount);
    }

    function claimRewards() external {
        _updateReward(msg.sender);

        uint256 reward = s.rewards[msg.sender];

        if (reward <= 0) {
            revert NoRewardsToClaim();
        }

        s.rewards[msg.sender] = 0;
        _mint(msg.sender, reward);

        emit RewardPaid(msg.sender, reward);
    }

    function _transferTokensIn(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount, 
        LibAppStorage.StakeType stakeType
    ) internal {
        if (stakeType == LibAppStorage.StakeType.ERC20) {
            if (tokenId != 0) {
                revert Erc20DoNotUseTokenId();
            }
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        } else if (stakeType == LibAppStorage.StakeType.ERC721) {
            if (amount != 1) {
                revert Erc721CanOnlyStake1Token();
            }
            IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        } else if (stakeType == LibAppStorage.StakeType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        }
    }

    function _transferTokensOut(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount, 
        LibAppStorage.StakeType stakeType
    ) internal {
        if (stakeType == LibAppStorage.StakeType.ERC20) {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        } else if (stakeType == LibAppStorage.StakeType.ERC721) {
            IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        } else if (stakeType == LibAppStorage.StakeType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        }
    }

    function _updateReward(address account) internal {
        if (s.totalStakedAmount > 0) {
            s.rewardPerTokenStored = _calculateRewardPerToken();
        }
        s.lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            s.rewards[account] = _earnedRewards(account);
            s.userRewardPerTokenPaid[account] = s.rewardPerTokenStored;
        }
    }

    function _calculateRewardPerToken() internal view returns (uint256) {
        uint256 timeDelta = block.timestamp - s.lastUpdateTime;
        if (s.totalStakedAmount == 0) {
            return s.rewardPerTokenStored;
        }

        return s.rewardPerTokenStored + (timeDelta * s.rewardRate * PRECISION) / (s.totalStakedAmount * REWARDS_DURATION);
    }

    function _earnedRewards(address account) internal view returns (uint256) {
        uint256 userTotalStaked = s.totalStakedByUser[account];
        return (userTotalStaked * (s.rewardPerTokenStored - s.userRewardPerTokenPaid[account])) / PRECISION + s.rewards[account];
    }

    function _mint(address to, uint256 amount) internal {
        s.balances[to] += amount;
        s.totalSupply += amount;
    }

    function getStakedTokens(address user) external view returns (LibAppStorage.StakeInfo[] memory) {
        return s.userStakes[user];
    }

    function getPendingRewards(address user) external view returns (uint256) {
        return _earnedRewards(user);
    }
}
