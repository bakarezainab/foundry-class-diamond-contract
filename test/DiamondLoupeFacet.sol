// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IDiamondCut } from "../contracts/interfaces/IDiamondCut.sol";
import { DiamondCutFacet } from "../contracts/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../contracts/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../contracts/facets/OwnershipFacet.sol";
import { Diamond } from "../contracts/Diamond.sol";
import "./helpers/DiamondUtils.sol";

contract DiamondLoupeFacetTest is DiamondUtils {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        diamond = new Diamond(address(this), address(diamondCutFacet));

        // Add facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        
        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testFacetAddresses() public {
        address[] memory addresses = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(addresses.length, 3); // DiamondCutFacet, DiamondLoupeFacet, OwnershipFacet
        assertTrue(containsAddress(addresses, address(diamondCutFacet)));
        assertTrue(containsAddress(addresses, address(diamondLoupeFacet)));
        assertTrue(containsAddress(addresses, address(ownershipFacet)));
    }

    function testFacetFunctionSelectors() public {
        bytes4[] memory selectors = DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(diamondLoupeFacet));
        assertEq(selectors.length, 5);
        assertTrue(containsSelector(selectors, DiamondLoupeFacet.facets.selector));
        assertTrue(containsSelector(selectors, DiamondLoupeFacet.facetFunctionSelectors.selector));
        assertTrue(containsSelector(selectors, DiamondLoupeFacet.facetAddresses.selector));
        assertTrue(containsSelector(selectors, DiamondLoupeFacet.facetAddress.selector));
        assertTrue(containsSelector(selectors, DiamondLoupeFacet.supportsInterface.selector));
    }

    function containsAddress(address[] memory addresses, address addr) internal pure returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == addr) return true;
        }
        return false;
    }

    function containsSelector(bytes4[] memory selectors, bytes4 selector) internal pure returns (bool) {
        for (uint i = 0; i < selectors.length; i++) {
            if (selectors[i] == selector) return true;
        }
        return false;
    }
}