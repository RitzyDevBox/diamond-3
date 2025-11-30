// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {Test1Facet} from "../src/facets/Test1Facet.sol";

import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract CacheBugTest is Test {
    Diamond diamond;
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    Test1Facet test1Facet;

    // selector values from JS test
    bytes4 constant ownerSel = 0x8da5cb5b;

    bytes4 constant sel0  = 0x19e3b533;
    bytes4 constant sel1  = 0x0716c2ae;
    bytes4 constant sel2  = 0x11046047;
    bytes4 constant sel3  = 0xcf3bbe18;
    bytes4 constant sel4  = 0x24c1d5a7;
    bytes4 constant sel5  = 0xcbb835f6;
    bytes4 constant sel6  = 0xcbb835f7;
    bytes4 constant sel7  = 0xcbb835f8;
    bytes4 constant sel8  = 0xcbb835f9;
    bytes4 constant sel9  = 0xcbb835fa;
    bytes4 constant sel10 = 0xcbb835fb;

    function setUp() public {
        // Deploy cut facet
        cutFacet = new DiamondCutFacet();

        // Deploy diamond
        diamond = new Diamond(address(this), address(cutFacet));

        // Deploy supporting facets
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        test1Facet = new Test1Facet();

        // Install loupe + ownership facets
        IDiamondCut.FacetCut[] memory baseCut = new IDiamondCut.FacetCut[](2);

        baseCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors()
        });

        baseCut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors()
        });

        IDiamondCut(address(diamond)).diamondCut(baseCut, address(0), "");

        // Add 11 selectors to fill slot 1 and start slot 2
        bytes4[] memory initialSelectors = new bytes4[](11);

        initialSelectors[0] = sel0;
        initialSelectors[1] = sel1;
        initialSelectors[2] = sel2;
        initialSelectors[3] = sel3;
        initialSelectors[4] = sel4;
        initialSelectors[5] = sel5;
        initialSelectors[6] = sel6;
        initialSelectors[7] = sel7;
        initialSelectors[8] = sel8;
        initialSelectors[9] = sel9;
        initialSelectors[10] = sel10;

        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(test1Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initialSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        // Now remove ownerSel, sel5, sel10
        bytes4[] memory removeList = new bytes4[](3);
        removeList[0] = ownerSel;
        removeList[1] = sel5;
        removeList[2] = sel10;

        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: removeList
        });

        IDiamondCut(address(diamond)).diamondCut(removeCut, address(0), "");
    }

    // ------------------------------------------------------------
    // TEST
    // ------------------------------------------------------------

    function test_cache_bug_fixed() public {
        bytes4[] memory selectors =
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(test1Facet));

        // must exist
        assertTrue(contains(selectors, sel0));
        assertTrue(contains(selectors, sel1));
        assertTrue(contains(selectors, sel2));
        assertTrue(contains(selectors, sel3));
        assertTrue(contains(selectors, sel4));
        assertTrue(contains(selectors, sel6));
        assertTrue(contains(selectors, sel7));
        assertTrue(contains(selectors, sel8));
        assertTrue(contains(selectors, sel9));

        // must NOT exist
        assertFalse(contains(selectors, ownerSel));
        assertFalse(contains(selectors, sel10));
        assertFalse(contains(selectors, sel5));
    }

    // ------------------------------------------------------------
    // Helper Functions
    // ------------------------------------------------------------

    function contains(bytes4[] memory arr, bytes4 sel) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] == sel) return true;
        }
        return false;
    }

    function loupeSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](4);
        s[0] = DiamondLoupeFacet.facets.selector;
        s[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        s[2] = DiamondLoupeFacet.facetAddresses.selector;
        s[3] = DiamondLoupeFacet.facetAddress.selector;
    }

    function ownershipSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = OwnershipFacet.owner.selector;
        s[1] = OwnershipFacet.transferOwnership.selector;
    }
}
