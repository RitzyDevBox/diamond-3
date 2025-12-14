library LibValidator {
    bytes32 internal constant STORAGE_POSITION =
        keccak256("diamond.validator.storage");

    struct ValidationStorage {
        address validator;
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
        ValidationStorage storage vs = vstore();
        return vs.whitelist[selector];
    }

    function setPublic(bytes4 selector, bool allowed) internal {
        ValidationStorage storage vs = vstore();
        vs.whitelist[selector] = allowed;
    }
}

