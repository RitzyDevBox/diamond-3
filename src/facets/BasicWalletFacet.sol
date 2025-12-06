// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract BasicWalletFacet {
    // =============================================================
    //                  ACCESS CONTROL HOOK
    // =============================================================
    // Replace with diamond’s actual access control:
    modifier onlyOperator() {
        // Example placeholder:
        // require(LibAccess.hasRole(msg.sender, LibAccess.OPERATOR_ROLE), "NOT_AUTHORIZED");

        require(msg.sender == tx.origin, "NOT_AUTHORIZED"); // REMOVE IN PROD
        _;
    }

    // =============================================================
    //                       NATIVE ETH
    // =============================================================

    /// @notice Send native ETH from the diamond to `to`.
    function sendETH(address to, uint256 amount) external onlyOperator {
        require(address(this).balance >= amount, "INSUFFICIENT_ETH");
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /// @notice Wrap ETH into WETH.
    function wrapETH(address weth, uint256 amount) external onlyOperator {
        require(address(this).balance >= amount, "INSUFFICIENT_ETH");
        IWETH(weth).deposit{ value: amount }();
    }

    /// @notice Unwrap WETH into native ETH.
    function unwrapETH(address weth, uint256 amount) external onlyOperator {
        IWETH(weth).withdraw(amount);
    }

    // =============================================================
    //                         ERC20
    // =============================================================

    /// @notice Transfer ERC20 tokens the diamond already owns.
    function sendERC20(address token, address to, uint256 amount)
        external
        onlyOperator
    {
        require(IERC20(token).transfer(to, amount), "ERC20_TRANSFER_FAILED");
    }

    /// @notice Approve a spender for ERC20 tokens.
    function approveERC20(address token, address spender, uint256 amount)
        external
        onlyOperator
    {
        require(IERC20(token).approve(spender, amount), "ERC20_APPROVE_FAILED");
    }

    // =============================================================
    //                         ERC721
    // =============================================================

    /// @notice Transfer an ERC721 the diamond owns.
    function sendERC721(address token, address to, uint256 tokenId)
        external
        onlyOperator
    {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice Approve an operator for a specific ERC721 token.
    function approveERC721(address token, address operator, uint256 tokenId)
        external
        onlyOperator
    {
        IERC721(token).approve(operator, tokenId);
    }

    /// @notice Approve or revoke operator approval for all NFTs.
    function setERC721ApprovalForAll(address token, address operator, bool approved)
        external
        onlyOperator
    {
        IERC721(token).setApprovalForAll(operator, approved);
    }

    // =============================================================
    //                  RECEIVE NATIVE ETH
    // =============================================================
    receive() external payable {}
}
