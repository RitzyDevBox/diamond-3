// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MockERC721 is IERC721 {
    string public name = "MockERC721";
    string public symbol = "M721";

    mapping(uint256 => address) public ownerOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => address) public getApproved;

    function balanceOf(address owner) external view returns (uint256) {
        owner; // suppress warning
        return 1; // irrelevant for tests
    }

    function mint(address to, uint256 tokenId) external {
        ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function approve(address operator, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender, "NOT_OWNER");
        getApproved[tokenId] = operator;
        emit Approval(msg.sender, operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "NOT_OWNER");
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);

        // if recipient is a contract → call onERC721Received
        if (to.code.length > 0) {
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "");
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC165
    }

    // Unused but required
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        transferFrom(from, to, tokenId);

        if (to.code.length > 0) {
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
        }
    }
}
