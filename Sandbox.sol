contract Sandbox {

    function generateHash(uint _identifier) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_identifier));
    }
}