// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library LibValidator {
    bytes32 internal constant STORAGE_POSITION =
        keccak256("diamond.validator.storage");

    struct ValidationStorage {
        address authorityResolver;
        mapping(bytes4 => bool) whitelist;
    }

    function vstore()
        internal
        pure
        returns (ValidationStorage storage vs)
    {
        bytes32 pos = STORAGE_POSITION;
        assembly { vs.slot := pos }
    }

    function isPublic(bytes4 selector) internal view returns (bool) {
        return vstore().whitelist[selector];
    }

    function setPublic(bytes4 selector, bool allowed) internal {
        vstore().whitelist[selector] = allowed;
    }

    function getAuthorityResolver() internal view returns (address) {
        return vstore().authorityResolver;
    }

    function setAuthorityResolver(address resolver) internal {
        vstore().authorityResolver = resolver;
    }
}
