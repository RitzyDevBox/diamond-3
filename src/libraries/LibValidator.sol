library LibValidator {
    bytes32 internal constant STORAGE_POSITION =
        keccak256("diamond.validator.storage");

    struct ValidationStorage {
        address validator;
    }

    function vstore()
        internal
        pure
        returns (ValidationStorage storage vs)
    {
        bytes32 pos = STORAGE_POSITION;
        assembly { vs.slot := pos }
    }
}
