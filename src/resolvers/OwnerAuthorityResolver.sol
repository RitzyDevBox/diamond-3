// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAuthorityResolver } from "../interfaces/IAuthorityResolver.sol";

contract OwnerAuthorityResolver is IAuthorityResolver {
    error NotFactory();
    error NotOwner();

    address public factory;
    mapping(address diamond => address owner) public ownerOf;

    event OwnerSet(address indexed diamond, address indexed owner);
    event OwnershipTransferred(
        address indexed diamond,
        address indexed previousOwner,
        address indexed newOwner
    );
    event FactorySet(address oldFactory, address newFactory);

    modifier onlyFactory() {
        if (msg.sender != factory) revert NotFactory();
        _;
    }

    modifier onlyOwner(address diamond) {
        if (msg.sender != ownerOf[diamond]) revert NotOwner();
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

    /// @notice Set initial owner (factory-only)
    function setOwner(address diamond, address owner) external onlyFactory {
        ownerOf[diamond] = owner;
        emit OwnerSet(diamond, owner);
    }

    /// @notice Transfer ownership (owner-only)
    function transferOwnership(address newOwner) external {
        address diamond = msg.sender;
        address prev = ownerOf[diamond];

        if (msg.sender != prev) revert NotOwner();

        ownerOf[diamond] = newOwner;
        emit OwnershipTransferred(diamond, prev, newOwner);
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
        // msg.sender is always the diamond due to fallback staticcall
        return caller == ownerOf[msg.sender];
    }
}
