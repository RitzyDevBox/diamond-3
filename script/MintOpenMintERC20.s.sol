// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IOpenMintERC20 {
    function mint(uint256 amount) external;
}

contract MintOpenMintERC20 is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // YOUR DEPLOYED TOKEN ADDRESS
        address token = 0x8900E4FCd3C2e6d5400fdE29719Eb8b5fc811b3c;

        // Mint 100 tokens to msg.sender
        uint256 amount = 100 ether;

        console2.log("Minting", amount, "to", vm.addr(pk));

        IOpenMintERC20(token).mint(amount);

        console2.log("Mint completed");

        vm.stopBroadcast();
    }
}
