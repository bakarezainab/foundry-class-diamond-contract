// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { ERC20 } from "../contracts/facets/ERC20Facet.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { Diamond } from "../contracts/Diamond.sol";
import "./helpers/DiamondUtils.sol";

contract ERC20FacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    ERC20 erc20;
    address owner;
    address user1;
    address user2;
    uint256 initialSupply;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1234);
        user2 = address(0x5678);
        initialSupply = 1000000 * 10**18; // 1 million tokens with 18 decimals
        
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        erc20 = new ERC20("Test Token", "TEST", 18, initialSupply, owner);

        // Add ERC20Facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc20),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC20")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testInitialState() public {
        assertEq(IERC20(address(diamond)).totalSupply(), initialSupply, "Total supply should be set");
        assertEq(IERC20(address(diamond)).balanceOf(owner), initialSupply, "Owner should have all tokens");
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10**18; // 1000 tokens
        IERC20(address(diamond)).transfer(user1, amount);
        
        assertEq(IERC20(address(diamond)).balanceOf(owner), initialSupply - amount, "Owner balance should decrease");
        assertEq(IERC20(address(diamond)).balanceOf(user1), amount, "Recipient balance should increase");
    }

    function testTransferFrom() public {
        uint256 amount = 1000 * 10**18; // 1000 tokens
        
        // First approve
        IERC20(address(diamond)).approve(user1, amount);
        assertEq(IERC20(address(diamond)).allowance(owner, user1), amount, "Allowance should be set");
        
        // Then transfer from
        vm.prank(user1);
        IERC20(address(diamond)).transferFrom(owner, user2, amount);
        
        assertEq(IERC20(address(diamond)).balanceOf(owner), initialSupply - amount, "Owner balance should decrease");
        assertEq(IERC20(address(diamond)).balanceOf(user2), amount, "Recipient balance should increase");
        assertEq(IERC20(address(diamond)).allowance(owner, user1), 0, "Allowance should be used up");
    }

    function testInsufficientBalance() public {
        uint256 amount = initialSupply + 1;
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        IERC20(address(diamond)).transfer(user1, amount);
    }

    function testInsufficientAllowance() public {
        uint256 amount = 1000 * 10**18;
        vm.prank(user1);
        vm.expectRevert("ERC20: insufficient allowance");
        IERC20(address(diamond)).transferFrom(owner, user2, amount);
    }

    function testApprove() public {
        uint256 amount = 1000 * 10**18;
        IERC20(address(diamond)).approve(user1, amount);
        assertEq(IERC20(address(diamond)).allowance(owner, user1), amount, "Allowance should be set");
    }
}