// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {DiamondFactory} from "../src/DiamondFactory.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {ValidationFacet} from "../src/facets/ValidationFacet.sol";
import {ExecuteFacet} from "../src/facets/ExecuteFacet.sol";
import {OwnerAuthorityResolver} from "../src/resolvers/OwnerAuthorityResolver.sol";
import {NFTAuthorityResolver} from "../src/resolvers/NFTAuthorityResolver.sol";


contract DeployDiamondFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        address deployer = vm.addr(deployerKey);
        // -------------------------------
        // Deploy all facets (singletons)
        // -------------------------------
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        ValidationFacet validationFacet = new ValidationFacet();
        ExecuteFacet executeFacet = new ExecuteFacet();
        
        OwnerAuthorityResolver ownerAuthorityResolver = new OwnerAuthorityResolver(deployer);
        NFTAuthorityResolver nftAuthorityResolver = new NFTAuthorityResolver(deployer);

        console2.log("DiamondCutFacet:       ", address(cutFacet));
        console2.log("DiamondLoupeFacet:     ", address(loupeFacet));
        console2.log("ValidationFacet:       ", address(validationFacet));
        console2.log("executeFacet:          ", address(executeFacet));
        console2.log("OwnerAuthorityResolver: ", address(ownerAuthorityResolver));
        console2.log("NFTAuthorityResolver: ", address(nftAuthorityResolver));

        // -------------------------------
        // Deploy factory with facet addrs
        // -------------------------------
        DiamondFactory factory = new DiamondFactory(
            address(cutFacet),
            address(loupeFacet),
            address(validationFacet),
            address(executeFacet)
        );

        ownerAuthorityResolver.setFactory(address(factory));
        nftAuthorityResolver.setFactory(address(factory));
        console2.log("DiamondFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
