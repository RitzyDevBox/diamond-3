// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import { Diamond } from "../src/Diamond.sol";

contract ComputeDiamondInitHash is Script {
    function run() external pure {
        // 🔴 MUST MATCH THE FACTORY CONSTRUCTOR ARG
        address cutFacet = 0x95d2EF6bbf1731E909F3D8Bf8DAec28AF7B5AE38;

        bytes memory initCode = abi.encodePacked(
            type(Diamond).creationCode,
            abi.encode(cutFacet)
        );

        bytes32 initCodeHash = keccak256(initCode);

        console2.log("Diamond init code hash:");
        console2.logBytes32(initCodeHash);
    }
}
