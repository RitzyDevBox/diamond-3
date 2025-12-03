// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {DiamondFactory} from "../src/DiamondFactory.sol";

contract DeployDiamondFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        DiamondFactory factory = new DiamondFactory();

        console2.log("DiamondFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
