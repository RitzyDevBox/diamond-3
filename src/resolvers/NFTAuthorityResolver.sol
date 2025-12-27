// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAuthorityResolver } from "../interfaces/IAuthorityResolver.sol";
import { IAuthorityInitializer } from "../interfaces/IAuthorityInitializer.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTAuthorityResolver is IAuthorityResolver, IAuthorityInitializer {
    error NotFactory();
    error AlreadyInitialized();

    address public factory;

    struct NFTAuthority {
        address nft;
        uint256 tokenId;
    }

    // diamond => NFT authority config
    mapping(address diamond => NFTAuthority) public authorityOf;

    event AuthorityInitialized(
        address indexed diamond,
        address indexed nft,
        uint256 indexed tokenId
    );

    event FactorySet(address oldFactory, address newFactory);

    modifier onlyFactory() {
        if (msg.sender != factory) revert NotFactory();
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function setFactory(address _factory) external onlyFactory {
        address oldFactory = factory;
        factory = _factory;
        emit FactorySet(oldFactory, _factory);
    }


    /// @notice Initialize NFT authority for a diamond (factory-only)
    /// @dev data = abi.encode(address nft, uint256 tokenId)
    function initialize(address diamond, bytes calldata data)
        external
        override
        onlyFactory
    {
        if (authorityOf[diamond].nft != address(0)) {
            revert AlreadyInitialized();
        }

        (address nft, uint256 tokenId) = abi.decode(data, (address, uint256));

        authorityOf[diamond] = NFTAuthority({
            nft: nft,
            tokenId: tokenId
        });

        emit AuthorityInitialized(diamond, nft, tokenId);
    }

    function isAuthorized(
        address caller,
        bytes4,
        bytes calldata,
        uint256
    )
        external
        view
        override
        returns (bool)
    {
        NFTAuthority memory auth = authorityOf[msg.sender];
        if (auth.nft == address(0)) return false;

        return IERC721(auth.nft).ownerOf(auth.tokenId) == caller;
    }
}
