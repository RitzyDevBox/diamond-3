// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorityResolver {
    function isAuthorized(
        address caller,
        bytes4 selector,
        bytes calldata data,
        uint256 value
    ) external view returns (bool);
}
