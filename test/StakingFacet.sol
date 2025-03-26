// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { Staking } from "../contracts/facets/StakingFacet.sol";
import { ERC20 } from "../contracts/facets/ERC20Facet.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { Diamond } from "../contracts/Diamond.sol";
import { LibAppStorage } from "../contracts/libraries/AppStorage.sol";
import "./helpers/DiamondUtils.sol";

contract StakingFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    Staking stakingFacet;
    ERC20 erc20;
    address owner;
    address user1;
    address user2;
    uint256 totalSupply;
    uint256 stakingAmount;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1234);
        user2 = address(0x5678);
        totalSupply = 1000000 * 10**18; // 1 million tokens
        stakingAmount = 1000 * 10**18; // 1000 tokens
        
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        erc20 = new ERC20("Test Token", "TEST", 18, totalSupply);
        stakingFacet = new Staking();

        // Add facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc20),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC20")
        });
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("StakingFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Transfer tokens to users for testing
        ERC20(address(diamond)).transfer(user1, stakingAmount);
        ERC20(address(diamond)).transfer(user2, stakingAmount);

        // Add ERC20 token as supported token
        vm.prank(owner);
        Staking(address(diamond)).addSupportedToken(address(erc20));
    }

    function testStakeERC20() public {
        // Approve staking
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        
        // Stake tokens
        vm.prank(user1);
        Staking(address(diamond)).stake(address(erc20), 0, stakingAmount, LibAppStorage.StakeType.ERC20);
        
        assertEq(IERC20(address(diamond)).balanceOf(address(diamond)), stakingAmount, "Diamond should hold staked tokens");
    }

    function testWithdrawERC20() public {
        // First stake
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stake(address(erc20), 0, stakingAmount, LibAppStorage.StakeType.ERC20);
        
        // Wait for some time
        vm.warp(block.timestamp + 30 days);
        
        // Then unstake
        vm.prank(user1);
        Staking(address(diamond)).unstake(address(erc20), 0, stakingAmount);
        
        assertEq(IERC20(address(diamond)).balanceOf(user1), stakingAmount, "User should receive tokens back");
    }

    function testRewards() public {
        // Setup staking
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stake(address(erc20), 0, stakingAmount, LibAppStorage.StakeType.ERC20);
        
        // Simulate time passing
        vm.warp(block.timestamp + 365 days);
        
        uint256 pendingRewards = Staking(address(diamond)).getPendingRewards(user1);
        assertTrue(pendingRewards > 0, "Should have accrued rewards");
        
        // Claim rewards
        vm.prank(user1);
        Staking(address(diamond)).claimRewards();
    }

    function testMultipleStakers() public {
        // User 1 stakes
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stake(address(erc20), 0, stakingAmount, LibAppStorage.StakeType.ERC20);
        
        // User 2 stakes double amount
        vm.prank(user2);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount * 2);
        vm.prank(user2);
        Staking(address(diamond)).stake(address(erc20), 0, stakingAmount * 2, LibAppStorage.StakeType.ERC20);
        
        // Move time forward
        vm.warp(block.timestamp + 365 days);
        
        // Check rewards ratio (User2 should have ~2x User1's rewards)
        uint256 user1Rewards = Staking(address(diamond)).getPendingRewards(user1);
        uint256 user2Rewards = Staking(address(diamond)).getPendingRewards(user2);
        
        assertApproxEqRel(user2Rewards, user1Rewards * 2, 0.01e18); // 1% tolerance
    }
}