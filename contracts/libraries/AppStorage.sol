// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

enum StakeType {
    ERC20,
    ERC721,
    ERC1155
}

struct StakeInfo {
    address user;
    address tokenAddress;
    uint256 tokenId;
    StakeType stakeType;
    uint256 amount;
    uint256 stakeTime;
    uint256 lastClaimTime;
}

struct AppStorage {
    // Token Reward Parameters
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    address owner;
 
    // Balances and allowances
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowance;

    // Staking-specific storage
    mapping(address => StakeInfo[]) userStakes;
    mapping(address => uint256) totalStakedByUser;
    
    // Staking parameters
    uint256 totalStakedAmount;
    uint256 rewardRate;
    uint256 rewardPerTokenStored;
    uint256 lastUpdateTime;
    
    // Rewards tracking
    mapping(address => uint256) userRewardPerTokenPaid;
    mapping(address => uint256) rewards;

    // Supported token types
    mapping(address => bool) supportedTokens;
}