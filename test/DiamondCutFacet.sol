// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUtils.sol";

contract MockFacet {
    function mockFunction1() external pure returns (uint256) {
        return 1;
    }

    function mockFunction2() external pure returns (uint256) {
        return 2;
    }
}

contract DiamondCutFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    MockFacet mockFacet;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = address(0x1234);
        
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        diamondLoupeFacet = new DiamondLoupeFacet();
        mockFacet = new MockFacet();

        // Add DiamondLoupeFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testAddNewFacet() public {
        // Prepare the facet cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MockFacet.mockFunction1.selector;
        selectors[1] = MockFacet.mockFunction2.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Execute the cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Verify the functions were added
        address facetAddress = DiamondLoupeFacet(address(diamond)).facetAddress(MockFacet.mockFunction1.selector);
        assertEq(facetAddress, address(mockFacet), "Function should be added to diamond");
    }

    function testReplaceFacet() public {
        // First add the original facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacet.mockFunction1.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Deploy new implementation
        MockFacet newMockFacet = new MockFacet();

        // Replace the facet
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newMockFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Verify the function was replaced
        address facetAddress = DiamondLoupeFacet(address(diamond)).facetAddress(MockFacet.mockFunction1.selector);
        assertEq(facetAddress, address(newMockFacet), "Function should point to new implementation");
    }

    function testRemoveFacet() public {
        // First add the facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacet.mockFunction1.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Remove the facet
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Verify the function was removed
        address facetAddress = DiamondLoupeFacet(address(diamond)).facetAddress(MockFacet.mockFunction1.selector);
        assertEq(facetAddress, address(0), "Function should be removed");
    }

    function testOnlyOwnerCanCut() public {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacet.mockFunction1.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Try to cut from non-owner address
        vm.prank(user);
        vm.expectRevert("LibDiamond: Must be contract owner");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testCannotAddDuplicateFunction() public {
        // First add the facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockFacet.mockFunction1.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Try to add the same function again
        vm.expectRevert("LibDiamondCut: Function already exists");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }
}