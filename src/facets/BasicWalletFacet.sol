// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract BasicWalletFacet {
    // =============================================================
    //                            ERRORS
    // =============================================================
    error InsufficientETH();
    error EthTransferFailed();
    error ERC20TransferFailed();
    error ERC20ApproveFailed();

    // =============================================================
    //                        NATIVE ETH
    // =============================================================

    /// @notice Send native ETH from the diamond to `to`.
    function sendETH(address to, uint256 amount) external {
        if (address(this).balance < amount) revert InsufficientETH();
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert EthTransferFailed();
    }

    /// @notice Wrap ETH into WETH.
    function wrapETH(address weth, uint256 amount) external {
        if (address(this).balance < amount) revert InsufficientETH();
        IWETH(weth).deposit{ value: amount }();
    }

    /// @notice Unwrap WETH into native ETH.
    function unwrapETH(address weth, uint256 amount) external {
        IWETH(weth).withdraw(amount);
    }

    // =============================================================
    //                         ERC20
    // =============================================================

    /// @notice Transfer ERC20 tokens the diamond already owns.
    function sendERC20(address token, address to, uint256 amount) external {
        if (!IERC20(token).transfer(to, amount)) revert ERC20TransferFailed();
    }

    /// @notice Approve a spender for ERC20 tokens.
    function approveERC20(address token, address spender, uint256 amount) external {
        if (!IERC20(token).approve(spender, amount)) revert ERC20ApproveFailed();
    }

    // =============================================================
    //                         ERC721
    // =============================================================

    /// @notice Transfer an ERC721 the diamond owns.
    function sendERC721(address token, address to, uint256 tokenId) external {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice Approve an operator for a specific ERC721 token.
    function approveERC721(address token, address operator, uint256 tokenId) external {
        IERC721(token).approve(operator, tokenId);
    }

    /// @notice Approve or revoke operator approval for all NFTs.
    function setERC721ApprovalForAll(
        address token,
        address operator,
        bool approved
    ) external {
        IERC721(token).setApprovalForAll(operator, approved);
    }

    /// @notice Required for receiving NFTs via safeTransferFrom.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // =============================================================
    //                    RECEIVE NATIVE ETH
    // =============================================================
    receive() external payable {}
}
