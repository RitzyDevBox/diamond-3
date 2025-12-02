// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Diamond} from "./Diamond.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {ValidationFacet} from "./facets/ValidationFacet.sol";
import {OwnerValidationModule} from "./facets/OwnerValidationModule.sol";

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract DiamondFactory {
    event DiamondDeployed(address indexed user, uint256 indexed seed, address diamond);

    /// @notice Deploy a Diamond using CREATE2 + seed
    /// @param seed Any user-chosen number (unique per wallet)
    function deployDiamond(uint256 seed)
        external
        returns (address diamondAddr)
    {
        // ------------------------------------------------------------
        // Deploy core facets
        // ------------------------------------------------------------
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ValidationFacet validationFacet = new ValidationFacet();
        OwnerValidationModule validator = new OwnerValidationModule();

        // ------------------------------------------------------------
        // CREATE2 deploy the Diamond
        // ------------------------------------------------------------
        bytes32 salt = keccak256(abi.encode(msg.sender, seed));

        diamondAddr = address(
            new Diamond{salt: salt}(msg.sender, address(cutFacet))
        );

        // ------------------------------------------------------------
        // Register loupe, ownership, and validation facets
        // ------------------------------------------------------------
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

        IDiamondCut(diamondAddr).diamondCut(baseCut, address(0), "");

        // ------------------------------------------------------------
        // Set validator = OwnerValidationModule
        // ------------------------------------------------------------
        ValidationFacet(diamondAddr).updateValidator(address(validator));

        emit DiamondDeployed(msg.sender, seed, diamondAddr);
    }

    // ------------------------------------------------------------
    // SELECTOR HELPERS
    // ------------------------------------------------------------
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

    function validationSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = ValidationFacet.getValidator.selector;
        s[1] = ValidationFacet.updateValidator.selector;
    }

    // ------------------------------------------------------------
    // VIEW: Compute address without deploying (nice UX)
    // ------------------------------------------------------------
    function computeDiamondAddress(address user, uint256 seed)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encode(user, seed));

        bytes memory bytecode = abi.encodePacked(
            type(Diamond).creationCode,
            abi.encode(user, address(0xDEAD)) // dummy cutFacet for prediction only
        );

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }
}
