// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {DiamondFactory} from "../src/DiamondFactory.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ValidationFacet} from "../src/facets/ValidationFacet.sol";
import {OwnerValidationFacet} from "../src/facets/OwnerValidationFacet.sol";
import {ExecuteFacet} from "../src/facets/ExecuteFacet.sol";


contract DeployDiamondFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // -------------------------------
        // Deploy all facets (singletons)
        // -------------------------------
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ValidationFacet validationFacet = new ValidationFacet();
        OwnerValidationFacet validator = new OwnerValidationFacet();
        ExecuteFacet executeFacet = new ExecuteFacet();

        console2.log("DiamondCutFacet:       ", address(cutFacet));
        console2.log("DiamondLoupeFacet:     ", address(loupeFacet));
        console2.log("OwnershipFacet:        ", address(ownershipFacet));
        console2.log("ValidationFacet:       ", address(validationFacet));
        console2.log("OwnerValidationFacet: ", address(validator));

        // -------------------------------
        // Deploy factory with facet addrs
        // -------------------------------
        DiamondFactory factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet),
            address(validationFacet),
            address(validator),
            address(executeFacet)
        );

        console2.log("DiamondFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
