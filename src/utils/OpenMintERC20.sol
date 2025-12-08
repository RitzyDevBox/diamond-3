// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OpenMintERC20 is ERC20 {
    uint256 public constant MAX_MINT = 100 ether; // 100 tokens per mint call

    constructor() ERC20("OpenMint", "OM20") {}

    /// @notice Anyone can mint up to 100 tokens per transaction.
    function mint(uint256 amount) external {
        require(amount <= MAX_MINT, "MINT_LIMIT");

        _mint(msg.sender, amount);
    }
}
