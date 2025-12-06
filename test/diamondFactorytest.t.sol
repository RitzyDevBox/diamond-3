// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondFactory} from "../src/DiamondFactory.sol";

import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ValidationFacet} from "../src/facets/ValidationFacet.sol";
import {OwnerValidationFacet} from "../src/facets/OwnerValidationFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IValidationModule} from "../src/interfaces/IValidationModule.sol";

/// ------------------------------------------------------------
/// Mock Facet
/// ------------------------------------------------------------
contract MockFacet {
    event Ping(address caller);
    function ping() external { emit Ping(msg.sender); }
}

/// ------------------------------------------------------------
/// TEST FACTORY
/// ------------------------------------------------------------
contract DiamondFactoryTest is Test {
    DiamondFactory factory;

    // Pre-deployed facet singletons
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    ValidationFacet validationFacet;
    OwnerValidationFacet ownerValidatorFacet;
    MockFacet mockFacet;

    address deployer = address(0xBEEF);
    address user     = address(0xCAFE);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy shared facets
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        validationFacet = new ValidationFacet();
        ownerValidatorFacet = new OwnerValidationFacet();
        mockFacet = new MockFacet();

        // Deploy factory
        factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet),
            address(validationFacet),
            address(ownerValidatorFacet)
        );

        vm.stopPrank();
    }

    /// ------------------------------------------------------------
    /// MAIN TEST — deploy wallet + verify
    /// ------------------------------------------------------------
    function testDeployDiamondAndValidate() public {
        vm.startPrank(user);

        // Deploy new diamond using seed=1
        address diamondAddr = factory.deployDiamond(1);

        // --------------- ASSERT OWNERSHIP -----------------
        address owner = OwnershipFacet(diamondAddr).owner();
        assertEq(owner, user, "Factory should transfer ownership to user");

        // --------------- ASSERT VALIDATOR SET -------------
        address v = ValidationFacet(diamondAddr).getValidator();
        assertEq(v, address(ownerValidatorFacet), "Validator should be OwnerValidationFacet");

        // --------------- ASSERT CALL ALLOWED (owner) ------

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[]( 1 ) ;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockValidatorSelectors()
        });

        IDiamondCut(diamondAddr).diamondCut(cut, address(0), "");
        
        vm.expectEmit(true, false, false, true);
        emit MockFacet.Ping(user);

        // Should succeed because user == owner
        MockFacet(diamondAddr).ping();

        vm.stopPrank();
    }

    /// ------------------------------------------------------------
    /// Test validator blocks non-owner
    /// ------------------------------------------------------------
    function testValidatorBlocksNonOwner() public {
        vm.startPrank(user);

        address diamondAddr = factory.deployDiamond(123);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockValidatorSelectors()
        });

        IDiamondCut(diamondAddr).diamondCut(cut, address(0), "");
    
        vm.stopPrank();

        // Non-owner
        vm.startPrank(address(0xBAD));

        vm.expectRevert(Diamond.NotAuthorized.selector);
        MockFacet(diamondAddr).ping();

        vm.stopPrank();
    }

    function mockValidatorSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = MockFacet.ping.selector;
    }
}
