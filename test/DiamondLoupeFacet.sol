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

contract DiamondLoupeFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    MockFacet mockFacet;

    function setUp() public {
        // Deploy the facets
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(diamondCutFacet));
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

    function testFacetAddresses() public {
        // Add mock facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("MockFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Get all facet addresses
        address[] memory addresses = DiamondLoupeFacet(address(diamond)).facetAddresses();
        
        // Should have DiamondCutFacet, DiamondLoupeFacet, and MockFacet
        assertEq(addresses.length, 3, "Should have three facets");
        assertTrue(
            containsAddress(addresses, address(diamondCutFacet)) &&
            containsAddress(addresses, address(diamondLoupeFacet)) &&
            containsAddress(addresses, address(mockFacet)),
            "Should contain all facet addresses"
        );
    }

    function testFacetFunctionSelectors() public {
        // Add mock facet
        bytes4[] memory selectors = generateSelectors("MockFacet");
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Get function selectors for mock facet
        bytes4[] memory facetSelectors = DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(mockFacet));
        assertEq(facetSelectors.length, selectors.length, "Should return all selectors");
        for(uint i = 0; i < selectors.length; i++) {
            assertTrue(containsSelector(facetSelectors, selectors[i]), "Should contain selector");
        }
    }

    function testFacetAddress() public {
        bytes4 selector = MockFacet.mockFunction1.selector;
        
        // Before adding facet
        address facetAddress = DiamondLoupeFacet(address(diamond)).facetAddress(selector);
        assertEq(facetAddress, address(0), "Should return zero address for unknown selector");

        // Add mock facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // After adding facet
        facetAddress = DiamondLoupeFacet(address(diamond)).facetAddress(selector);
        assertEq(facetAddress, address(mockFacet), "Should return correct facet address");
    }

    function containsAddress(address[] memory addresses, address addr) internal pure returns (bool) {
        for(uint i = 0; i < addresses.length; i++) {
            if(addresses[i] == addr) return true;
        }
        return false;
    }

    function containsSelector(bytes4[] memory selectors, bytes4 selector) internal pure returns (bool) {
        for(uint i = 0; i < selectors.length; i++) {
            if(selectors[i] == selector) return true;
        }
        return false;
    }
}