// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IValidationModule {
    function validate(
        address caller,
        bytes4 selector,
        bytes calldata data,
        uint256 value
    ) external view returns (bool);
}
