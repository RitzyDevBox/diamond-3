// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IValidationModule } from "../interfaces/IValidationModule.sol";

error NotAuthorized();
error InvalidValidator();

contract ValidationFacet {
    bytes32 private constant VALIDATOR_SLOT =
        keccak256("diamond.6900.validation.module");

    event ValidatorChanged(address oldValidator, address newValidator);

    function _getValidator() internal view returns (IValidationModule module) {
        bytes32 slot = VALIDATOR_SLOT;
        assembly {
            module := sload(slot)
        }
    }

    function _setValidator(address module) internal {
        if (module == address(0)) revert InvalidValidator();
        bytes32 slot = VALIDATOR_SLOT;
        assembly {
            sstore(slot, module)
        }
    }

    /// EXTERNAL 6900: Set validator
    function setValidator(address module) external {
        LibDiamond.enforceIsContractOwner();
        address old = address(_getValidator());
        _setValidator(module);
        emit ValidatorChanged(old, module);
    }

    /// READ 6900 validator
    function getValidator() external view returns (address) {
        return address(_getValidator());
    }

    /// 6900 INVOKE STANDARD
    function invoke(bytes calldata data)
        external
        payable
        returns (bytes memory)
    {
        IValidationModule validator = _getValidator();

        if (!validator.validate(msg.sender, bytes4(data[0:4]), data, msg.value))
            revert NotAuthorized();

        // Route to fallback manual call
        return _callSelf(data);
    }

    function _callSelf(bytes calldata data)
        internal
        returns (bytes memory result)
    {
        (bool ok, bytes memory ret) =
            address(this).call(data);

        if (!ok) assembly {
            revert(add(ret, 32), mload(ret))
        }

        return ret;
    }
}
