// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IValidationModule } from "../interfaces/IValidationModule.sol";

contract ValidationFacet {
    event ValidatorUpdated(address indexed oldValidator, address indexed newValidator);

    /// @notice Update global validation module
    /// @dev Only diamond owner may call this
    function updateValidator(address newValidator) external {
        LibDiamond.enforceIsContractOwner();
        address old = LibDiamond.getValidator();
        LibDiamond.setValidator(newValidator);

        emit ValidatorUpdated(old, newValidator);
    }

    /// @notice Returns the globally configured validator contract
    function getValidator() external view returns (address) {
        return LibDiamond.getValidator();
    }
}
