// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {Test1Facet} from "../src/facets/Test1Facet.sol";
import {Test2Facet} from "../src/facets/Test2Facet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract DiamondTest is Test {
    Diamond diamond;
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownership;
    address[] facetAddresses;

    function setUp() public {
        // Deploy cut facet
        cutFacet = new DiamondCutFacet();
        
        // Deploy diamond
        diamond = new Diamond(address(this), address(cutFacet));

        // Deploy loupe + ownership facets
        loupeFacet = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors()
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownership),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors()
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

    function ownershipSelectors() internal pure returns (bytes4[] memory sel) {
        sel = new bytes4[](2);
        sel[0] = OwnershipFacet.owner.selector;
        sel[1] = OwnershipFacet.transferOwnership.selector;
    }

    function selectorsFor(address facet) internal pure returns (bytes4[] memory selectors) {
        selectors = IFacetIntrospection(facet).selectors();
    }

    // ------------------------
    // TESTS
    // ------------------------

    function testFacetCount() public {
        assertEq(facetAddresses.length, 3);
    }

    function testSelectorAssignments() public {
        // DiamondCutFacet selectors
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = DiamondCutFacet.diamondCut.selector;

        assertEqArrayLike(
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(facetAddresses[0]),
            cutSelectors
        );

        // DiamondLoupeFacet selectors
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;

        assertEqArrayLike(
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(facetAddresses[1]),
            loupeSelectors
        );

        // OwnershipFacet selectors
        bytes4[] memory ownerSelectors = new bytes4[](2);
        ownerSelectors[0] = OwnershipFacet.owner.selector;
        ownerSelectors[1] = OwnershipFacet.transferOwnership.selector;

        assertEqArrayLike(
            IDiamondLoupe(address(diamond)).facetFunctionSelectors(facetAddresses[2]),
            ownerSelectors
        );
    }


    function testFacetAddressMapping() public {
        assertEq(
            IDiamondLoupe(address(diamond)).facetAddress(bytes4(0x1f931c1c)),
            facetAddresses[0]
        );
        assertEq(
            IDiamondLoupe(address(diamond)).facetAddress(bytes4(0xcdffacc6)),
            facetAddresses[1]
        );
        assertEq(
            IDiamondLoupe(address(diamond)).facetAddress(bytes4(0xf2fde38b)),
            facetAddresses[2]
        );
    }

    // ------------------------
    // ARR COMPARE UTIL
    // ------------------------

    function assertEqArrayLike(bytes4[] memory a, bytes4[] memory b) internal {
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
