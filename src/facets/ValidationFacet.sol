// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IValidationModule } from "../interfaces/IValidationModule.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract ValidationFacet {

    /// @notice Returns the facet address that implements the `validate` function.
    /// @dev No storage — uses Diamond selector table.
    function getValidator() external view returns (address) {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }

        return ds.selectorToFacetAndPosition[
            IValidationModule.validate.selector
        ].facetAddress;
    }
}
