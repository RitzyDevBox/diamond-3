// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Optional interface for authority resolvers that need initialization
interface IAuthorityInitializer {
    /// @dev Called once by the factory immediately after diamond deployment
    /// @param diamond The newly deployed diamond address
    /// @param data Opaque, resolver-specific initialization data
    function initialize(address diamond, bytes calldata data) external;
}
