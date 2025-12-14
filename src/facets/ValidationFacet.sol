// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IValidationModule } from "../interfaces/IValidationModule.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibValidator } from "../libraries/LibValidator.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract ValidationFacet {
    
    // ------------------------------------------------------------
    // PUBLIC HELPER FOR UI & MODULES
    // ------------------------------------------------------------
    function getValidator() external view returns (address) {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;

        assembly { ds.slot := position }

        return ds.selectorToFacetAndPosition[
            IValidationModule.validate.selector
        ].facetAddress;
    }

    // ------------------------------------------------------------
    // WHITELIST MANAGEMENT
    // ------------------------------------------------------------
    function setPublicSelector(bytes4[] memory selectors, bool allowed) external {
        uint256 len = selectors.length;
        for (uint256 i; i < len;) {
            LibValidator.setPublic(selectors[i], allowed);
            unchecked { ++i; }
        }
    }

    function isPublicSelector(bytes4 selector) external view returns (bool) {
        return LibValidator.isPublic(selector);
    }
}
