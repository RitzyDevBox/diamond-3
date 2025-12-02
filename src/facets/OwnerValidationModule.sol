// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IValidationModule} from "../interfaces/IValidationModule.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract OwnerValidationModule is IValidationModule {
    function validate(
        address sender,
        bytes4,
        bytes calldata,
        uint256
    ) external view override returns (bool) {
        return sender == LibDiamond.contractOwner();
    }
}
