// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IValidationModule } from "../interfaces/IValidationModule.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibValidator } from "../libraries/LibValidator.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IAuthorityResolver } from "../interfaces/IAuthorityResolver.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract ValidationFacet is IValidationModule {
    
    function validate(
        address caller,
        bytes4 selector,
        bytes calldata data,
        uint256 value
    )
        external
        view
        override
        returns (bool)
    {
        // Public functions always allowed
        if (LibValidator.isPublic(selector)) {
            return true;
        }

        address resolver = LibValidator.getAuthorityResolver();
        if (resolver == address(0)) {
            // permissionless by default (setup phase)
            return true;
        }

        (bool ok, bytes memory ret) = resolver.staticcall(
            abi.encodeWithSelector(
                IAuthorityResolver.isAuthorized.selector,
                caller,
                selector,
                data,
                value
            )
        );

        return ok && ret.length == 32 && abi.decode(ret, (bool));
    }


    function getAuthorizer() external view returns (address) {
        return LibValidator.getAuthorityResolver();
    }

    function setAuthorizer(address _resolver) external {
        return LibValidator.setAuthorityResolver(_resolver);
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
