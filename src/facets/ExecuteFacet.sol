// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ExecuteFacet {
    error InvalidTarget();

    event Executed(address indexed target, uint256 value, bytes data, bytes result);
    event BatchExecuted(uint256 count);

    struct ExecCall {
        address to;
        uint256 value;
        bytes data;
    }

    function _executeInternal(
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory result) {
        if (to == address(0)) revert InvalidTarget();

        (bool ok, bytes memory ret) = to.call{value: value}(data);

        if (!ok) {
            //This will propagate the error instead of rethrowing
            assembly {
                revert(add(ret, 32), mload(ret))
            }
        }

        return ret;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory result) {
        result = _executeInternal(to, value, data);
        emit Executed(to, value, data, result);
    }

    function batchExecute(
        ExecCall[] calldata calls
    ) external returns (bytes[] memory results) {
        uint256 len = calls.length;
        results = new bytes[](len);

        for (uint256 i = 0; i < len; ) {
            ExecCall calldata c = calls[i];
            results[i] = _executeInternal(c.to, c.value, c.data);
            unchecked { ++i; }
        }

        emit BatchExecuted(len);
    }
}
