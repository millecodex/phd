// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataAnchor {
    bytes32[] public hashList;
    mapping(bytes32 => bool) public isHashStored;  // Mapping to track stored hashes
    
    event HashAdded(address indexed sender, bytes32 indexed hash, string message);

    function addHash(bytes32 _hash, string calldata _message) external {
        // Check that the hash has not been stored before
        require(!isHashStored[_hash], "Hash already stored");

        // Check that the message is not too long
        require(bytes(_message).length <= 100, "Message too long");

        // Add the hash to the list
        hashList.push(_hash);
        
        // Mark the hash as stored
        isHashStored[_hash] = true;

        // Emit the event
        emit HashAdded(msg.sender, _hash, _message);
    }
    
    function getHash(uint256 index) external view returns (bytes32) {
        require(index < hashList.length, "Index out of bounds");
        return hashList[index];
    }
    
    function getHashCount() external view returns (uint256) {
        return hashList.length;
    }

    fallback() external {
        revert("Contract cannot accept Ether");
    }
}
