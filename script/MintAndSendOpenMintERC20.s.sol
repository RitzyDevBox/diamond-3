// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IOpenMintERC20 {
    function mint(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

contract MintAndSendOpenMintERC20 is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address sender = vm.addr(pk);

        vm.startBroadcast(pk);

        // -----------------------
        // Token + recipient info
        // -----------------------
        address token = 0x8900E4FCd3C2e6d5400fdE29719Eb8b5fc811b3c;
        address recipient = 0x6dC2F30D8D2b1683617AaECd98941D7e56cA61A1;

        uint256 amount = 100 ether;

        console2.log("Minting", amount, "tokens to:", sender);

        // Mint to yourself
        IOpenMintERC20(token).mint(amount);

        uint256 balAfterMint = IOpenMintERC20(token).balanceOf(sender);
        console2.log("Balance after mint:", balAfterMint);

        // Send tokens
        console2.log("Sending tokens to:", recipient);
        IOpenMintERC20(token).transfer(recipient, amount);

        uint256 balAfterSendSender = IOpenMintERC20(token).balanceOf(sender);
        uint256 balAfterSendRecipient = IOpenMintERC20(token).balanceOf(recipient);

        console2.log("Sender balance after send:", balAfterSendSender);
        console2.log("Recipient balance after send:", balAfterSendRecipient);

        vm.stopBroadcast();
    }
}
