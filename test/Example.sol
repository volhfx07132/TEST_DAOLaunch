pragma solidity ^0.8.0;

contract Example {
    function testRecovery(address _addr, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _addr));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr;
    }
}