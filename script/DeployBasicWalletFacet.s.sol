// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import { BasicWalletFacet } from "../src/facets/BasicWalletFacet.sol";

contract DeployBasicWalletFacet is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        BasicWalletFacet walletFacet = new BasicWalletFacet();
        console2.log("BasicWalletFacet deployed at:", address(walletFacet));

        vm.stopBroadcast();
    }
}
