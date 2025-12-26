// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract DiamondTest is Test {
    Diamond diamond;
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    address[] facetAddresses;

    function setUp() public {
        // Deploy cut facet
        cutFacet = new DiamondCutFacet();
        
        // Deploy diamond
        diamond = new Diamond(address(cutFacet));

        // Deploy loupe + ownership facets
        loupeFacet = new DiamondLoupeFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors()
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        facetAddresses = IDiamondLoupe(address(diamond)).facetAddresses();
    }

    // ------------------------
    // SELECTOR HELPERS
    // ------------------------

    function loupeSelectors() internal pure returns (bytes4[] memory sel) {
        sel = new bytes4[](4);
        sel[0] = IDiamondLoupe.facets.selector;
        sel[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        sel[2] = IDiamondLoupe.facetAddresses.selector;
        sel[3] = IDiamondLoupe.facetAddress.selector;
    }

    function selectorsFor(address facet) internal pure returns (bytes4[] memory selectors) {
        selectors = IFacetIntrospection(facet).selectors();
    }


    function testSelectorAssignments() public {
        // DiamondCutFacet selectors
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = DiamondCutFacet.diamondCut.selector;

        assertEqArrayLike(
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(facetAddresses[0]),
            cutSelectors
        );

        assertEqArrayLike(
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(facetAddresses[1]),
            loupeSelectors()
        );
    }



    // ------------------------
    // ARR COMPARE UTIL
    // ------------------------

    function assertEqArrayLike(bytes4[] memory a, bytes4[] memory b) pure internal {
        assertEq(a.length, b.length, "len mismatch");
        bool found;
        for (uint256 i; i < a.length; i++) {
            found = false;
            for (uint256 j; j < b.length; j++) {
                if (a[i] == b[j]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "missing selector");
        }
    }
}

interface IFacetIntrospection {
    function selectors() external pure returns (bytes4[] memory);
}
