// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import { OpenMintERC20 } from "../src/utils/OpenMintERC20.sol";

contract DeployOpenMintERC20 is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // -------------------------------
        // Deploy OpenMint ERC20
        // -------------------------------
        OpenMintERC20 token = new OpenMintERC20();

        console2.log("OpenMintERC20 deployed at:", address(token));
        console2.log("Name:     ", token.name());
        console2.log("Symbol:   ", token.symbol());
        console2.log("Decimals: ", token.decimals());

        vm.stopBroadcast();
    }
}
