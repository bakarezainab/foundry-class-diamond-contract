// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUtils.sol";

contract OwnershipFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    OwnershipFacet ownershipFacet;
    address owner;
    address newOwner;

    function setUp() public {
        owner = address(this);
        newOwner = address(0x1234);
        
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        ownershipFacet = new OwnershipFacet();

        // Add OwnershipFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testInitialOwner() public {
        address currentOwner = OwnershipFacet(address(diamond)).owner();
        assertEq(currentOwner, owner, "Initial owner should be set correctly");
    }

    function testTransferOwnership() public {
        // Transfer ownership
        OwnershipFacet(address(diamond)).transferOwnership(newOwner);
        
        // Verify new owner
        address currentOwner = OwnershipFacet(address(diamond)).owner();
        assertEq(currentOwner, newOwner, "Ownership should be transferred");
    }

    function testOnlyOwnerCanTransfer() public {
        // Try to transfer from non-owner address
        vm.prank(newOwner);
        vm.expectRevert("LibDiamond: Must be contract owner");
        OwnershipFacet(address(diamond)).transferOwnership(newOwner);
    }
}