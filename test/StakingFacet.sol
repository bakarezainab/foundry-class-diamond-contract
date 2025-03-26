// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { Staking } from "../contracts/facets/StakingFacet.sol";
import { ERC20 } from "../contracts/facets/ERC20Facet.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { Diamond } from "../contracts/Diamond.sol";
import "./helpers/DiamondUtils.sol";

contract StakingFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    Staking stakingFacet;
    ERC20 erc20;
    address owner;
    address user1;
    address user2;
    uint256 initialSupply;
    uint256 stakingAmount;
    uint256 constant APR = 1000; // 10% APR
    uint256 constant MIN_LOCK = 7 days;
    uint256 constant DECAY_RATE = 100; // 1% decay
    uint256 constant PENALTY = 1000; // 10% penalty

    function setUp() public {
        owner = address(this);
        user1 = address(0x1234);
        user2 = address(0x5678);
        initialSupply = 1000000 * 10**18; // 1 million tokens
        stakingAmount = 1000 * 10**18; // 1000 tokens
        
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        erc20 = new ERC20("Test Token", "TEST", 18, initialSupply, owner);
        stakingFacet = new Staking(address(erc20), APR, MIN_LOCK, DECAY_RATE, PENALTY);

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
    }

    function testStakeERC20() public {
        // Approve staking
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        
        // Stake tokens
        vm.prank(user1);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        assertEq(IERC20(address(diamond)).balanceOf(address(diamond)), stakingAmount, "Diamond should hold staked tokens");
    }

    function testWithdrawERC20() public {
        // First stake
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        // Wait for lock period
        vm.warp(block.timestamp + MIN_LOCK);
        
        // Then withdraw
        vm.prank(user1);
        Staking(address(diamond)).withdrawERC20(stakingAmount);
        
        assertEq(IERC20(address(diamond)).balanceOf(user1), stakingAmount, "User should receive tokens back");
    }

    function testCannotWithdrawBeforeLockPeriod() public {
        // First stake
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        // Try to withdraw before lock period
        vm.prank(user1);
        vm.expectRevert("Lock duration not met");
        Staking(address(diamond)).withdrawERC20(stakingAmount);
    }

    function testRewards() public {
        // Setup staking
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        // Simulate time passing
        vm.warp(block.timestamp + 1 days);
        
        // Claim rewards
        vm.prank(user1);
        Staking(address(diamond)).claimRewards();
    }

    function testMultipleStakers() public {
        // User 1 stakes
        vm.prank(user1);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user1);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        // User 2 stakes
        vm.prank(user2);
        ERC20(address(diamond)).approve(address(diamond), stakingAmount);
        vm.prank(user2);
        Staking(address(diamond)).stakeERC20(address(erc20), stakingAmount);
        
        assertEq(IERC20(address(diamond)).balanceOf(address(diamond)), stakingAmount * 2, "Diamond should hold all staked tokens");
    }
}