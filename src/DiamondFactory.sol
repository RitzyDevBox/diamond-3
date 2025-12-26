// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Diamond} from "./Diamond.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {ValidationFacet} from "./facets/ValidationFacet.sol";
import {ExecuteFacet} from "./facets/ExecuteFacet.sol";
import {IAuthorityInitializer} from "./interfaces/IAuthorityInitializer.sol";

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
// import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DiamondFactory {
    event DiamondDeployed(address indexed user, uint256 indexed seed, address diamond);

    // ------------------------------------------------------------
    // Deploy core facets
    // ------------------------------------------------------------
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    ValidationFacet validationFacet;
    ExecuteFacet executeFacet; 

    constructor(
        address _cutFacet,
        address _loupeFacet,
        address _validationFacet,
        address _executeFacet
    ) {
        cutFacet = DiamondCutFacet(_cutFacet);
        loupeFacet = DiamondLoupeFacet(_loupeFacet);
        validationFacet = ValidationFacet(_validationFacet);
        executeFacet = ExecuteFacet(_executeFacet);
    }

    /// @notice Deploy a Diamond using CREATE2 + seed
    /// @param seed Any user-chosen number (unique per wallet)
    function deployDiamond(uint256 seed, address defaultAuthorizer, bytes calldata options)
        external
        returns (address diamondAddr)
    {
        // ------------------------------------------------------------
        // CREATE2 deploy the Diamond
        // ------------------------------------------------------------
        bytes32 salt = keccak256(abi.encode(msg.sender, seed));

        diamondAddr = address(
            new Diamond{salt: salt}(address(cutFacet))
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
            facetAddress: address(validationFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: validationSelectors()
        });

        baseCut[2] = IDiamondCut.FacetCut({
            facetAddress: address(executeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: executeFacetSelectors()
        });

        IDiamondCut(diamondAddr).diamondCut(baseCut, address(0), "");
        initValidationWhitelist(diamondAddr);
        
        ValidationFacet(diamondAddr).setAuthorizer(address(defaultAuthorizer));
        
        IAuthorityInitializer(defaultAuthorizer).initialize(diamondAddr, options);
        //OwnershipFacet(diamondAddr).transferOwnership(msg.sender);

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

    function validationSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](5);
        s[0] = ValidationFacet.getAuthorizer.selector;
        s[1] = ValidationFacet.setAuthorizer.selector;
        s[2] = ValidationFacet.setPublicSelector.selector;
        s[3] = ValidationFacet.isPublicSelector.selector;
        s[4] = ValidationFacet.validate.selector;
    }

    function executeFacetSelectors() internal pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = ExecuteFacet.execute.selector;
        s[1] = ExecuteFacet.batchExecute.selector;
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
            abi.encode(address(cutFacet))
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
        selectors[4] = ValidationFacet.getAuthorizer.selector;
        selectors[5] = ValidationFacet.isPublicSelector.selector;
        // selectors[5] = IERC721Receiver.onERC721Received.selector;
        //selectors[6] = IERC165.supportsInterface.selector;

        ValidationFacet(diamondAddr).setPublicSelector(selectors, true);
    }

}
