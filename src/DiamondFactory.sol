// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Diamond} from "./Diamond.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {ValidationFacet} from "./facets/ValidationFacet.sol";
import {OwnerValidationFacet} from "./facets/OwnerValidationFacet.sol";

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DiamondFactory {
    event DiamondDeployed(address indexed user, uint256 indexed seed, address diamond);

    // ------------------------------------------------------------
    // Deploy core facets
    // ------------------------------------------------------------
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    OwnershipFacet ownershipFacet;
    ValidationFacet validationFacet;
    OwnerValidationFacet validator;

    constructor(
        address _cutFacet,
        address _loupeFacet,
        address _ownershipFacet,
        address _validationFacet,
        address _validator
    ) {
        cutFacet = DiamondCutFacet(_cutFacet);
        loupeFacet = DiamondLoupeFacet(_loupeFacet);
        ownershipFacet = OwnershipFacet(_ownershipFacet);
        validationFacet = ValidationFacet(_validationFacet);
        validator = OwnerValidationFacet(_validator);
    }

    /// @notice Deploy a Diamond using CREATE2 + seed
    /// @param seed Any user-chosen number (unique per wallet)
    function deployDiamond(uint256 seed)
        external
        returns (address diamondAddr)
    {
        // ------------------------------------------------------------
        // CREATE2 deploy the Diamond
        // ------------------------------------------------------------
        bytes32 salt = keccak256(abi.encode(msg.sender, seed));

        diamondAddr = address(
            new Diamond{salt: salt}(address(this), address(cutFacet))
        );

        // ------------------------------------------------------------
        // Register loupe, ownership, and validation facets
        // ------------------------------------------------------------
        IDiamondCut.FacetCut[] memory baseCut = new IDiamondCut.FacetCut[](4);

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

        baseCut[3] = IDiamondCut.FacetCut({
            facetAddress: address(validator),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownerValidationSelectors()
        });


        IDiamondCut(diamondAddr).diamondCut(baseCut, address(0), "");
        initValidationWhitelist(diamondAddr);
        
        // ------------------------------------------------------------
        // Set validator = OwnerValidationModule
        // ------------------------------------------------------------
        OwnershipFacet(diamondAddr).transferOwnership(msg.sender);

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
        s = new bytes4[](3);
        s[0] = ValidationFacet.getValidator.selector;
        s[1] = ValidationFacet.setPublicSelector.selector;
        s[2] = ValidationFacet.isPublicSelector.selector;
    }

    function ownerValidationSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = OwnerValidationFacet.validate.selector;
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
            abi.encode(address(this), address(cutFacet))
        );

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    function initValidationWhitelist(address diamondAddr) internal {
        bytes4[] memory selectors = new bytes4[](6);

        selectors[0] = IDiamondLoupe.facets.selector;
        selectors[1] = IDiamondLoupe.facetAddresses.selector;
        selectors[2] = IDiamondLoupe.facetFunctionSelectors.selector;
        selectors[3] = IDiamondLoupe.facetAddress.selector;
        selectors[4] = ValidationFacet.getValidator.selector;
        selectors[5] = IERC721Receiver.onERC721Received.selector;
        //selectors[6] = IERC165.supportsInterface.selector;

        ValidationFacet(diamondAddr).setPublicSelector(selectors, true);
    }

}
