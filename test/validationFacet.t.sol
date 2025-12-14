// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ValidationFacet} from "../src/facets/ValidationFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IValidationModule} from "../src/interfaces/IValidationModule.sol";
import {OwnerValidationFacet} from "../src/facets/OwnerValidationFacet.sol";

contract AllowValidator is IValidationModule {
    function validate(
        address,
        bytes4,
        bytes calldata,
        uint256
    )
        external
        view
        returns (bool)
    {
        return true;
    }
}

contract DenyValidator is IValidationModule {
    function validate(
        address,
        bytes4,
        bytes calldata,
        uint256
    )
        external
        view
        returns (bool)
    {
        return false;
    }
}

contract MockFacet {
    event Ping(address caller);

    function ping() external {
        emit Ping(msg.sender);
    }
}

contract ValidationFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    ValidationFacet validationFacet;

    AllowValidator allowValidator;
    DenyValidator denyValidator;
    MockFacet mockFacet;


    function setUp() public {
        // Deploy cut facet
        cutFacet = new DiamondCutFacet();

        // Deploy diamond
        diamond = new Diamond(address(this), address(cutFacet));

        // Deploy supporting facets
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        validationFacet = new ValidationFacet();

        // Deploy mock validator modules
        allowValidator = new AllowValidator();
        denyValidator = new DenyValidator();

        // Deploy mock facet (a simple callable function)
        mockFacet = new MockFacet();

        // Install loupe + ownership facets
        IDiamondCut.FacetCut[] memory baseCut = new IDiamondCut.FacetCut[](3);

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

        baseCut[2] = IDiamondCut.FacetCut({
            facetAddress: address(validationFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: validationSelectors()
        });

        IDiamondCut(address(diamond)).diamondCut(baseCut, address(0), "");

                // Add mockFacet to the diamond
        IDiamondCut.FacetCut[] memory mc = new IDiamondCut.FacetCut[](1);

        mc[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockValidatorSelectors()
        });

        IDiamondCut(address(diamond)).diamondCut(mc, address(0), "");
    }

    // ------------------------------------------------------------
    // TEST
    // ------------------------------------------------------------

    function test_defaultValidator_allowsCalls() public {
        MockFacet(address(diamond)).ping(); // should NOT revert
    }

    function test_allowValidator_allowsCalls() public {
        installValidator(address(allowValidator));
        MockFacet(address(diamond)).ping(); // should NOT revert
    }

    function test_denyValidator_blocksCalls() public {
        installValidator(address(denyValidator));
        vm.expectRevert(Diamond.NotAuthorized.selector);
        MockFacet(address(diamond)).ping();
    }

    // ------------------------------------------------------------
    // Helper Functions
    // ------------------------------------------------------------

    function installValidator(address validatorAddress) internal {
        IDiamondCut.FacetCut[] memory baseCut = new IDiamondCut.FacetCut[](1);
        baseCut[0] = IDiamondCut.FacetCut({
            facetAddress: validatorAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: IValidationModuleSelectors()
        });

        IDiamondCut(address(diamond)).diamondCut(baseCut, address(0), "");
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

    function validationOperationSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = ValidationFacet.getValidator.selector;
    }

    function validationSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](3);
        s[0] = ValidationFacet.getValidator.selector;
        s[1] = ValidationFacet.setPublicSelector.selector;
        s[2] = ValidationFacet.isPublicSelector.selector;
    }

    function IValidationModuleSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = IValidationModule.validate.selector;
    }

    function mockValidatorSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = MockFacet.ping.selector;
    }

    function test_publicSelector_bypassesValidation() public {
        bytes4[] memory arr = new bytes4[](1);
        arr[0] = MockFacet.ping.selector;
        ValidationFacet(address(diamond)).setPublicSelector(arr, true);

        // install deny validator
        installValidator(address(denyValidator));

        // should NOT revert because it's public
        MockFacet(address(diamond)).ping();
    }

    function test_nonPublicSelector_isBlocked() public {
        // make sure it's NOT public
        bytes4[] memory arr = new bytes4[] (1);
        arr[0] = MockFacet.ping.selector;
        ValidationFacet(address(diamond)).setPublicSelector(arr, false);

        // install deny validator
        installValidator(address(denyValidator));

        vm.expectRevert(Diamond.NotAuthorized.selector);
        MockFacet(address(diamond)).ping();
    }
}
