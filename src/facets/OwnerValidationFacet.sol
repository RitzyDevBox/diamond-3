// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IValidationModule} from "../interfaces/IValidationModule.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract OwnerValidationFacet is IValidationModule {

    /// @notice Validate call based on diamond owner
    function validate(
        address caller,
        bytes4,      // selector (unused)
        bytes calldata, // data (unused)
        uint256       // value (unused)
    )
        external
        view
        override
        returns (bool)
    {
        return caller == LibDiamond.contractOwner();
    }
}
