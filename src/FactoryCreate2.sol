// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract FactoryCREATE2 {
    struct Commitment {
        mapping(address => mapping(bytes32 => uint256)) blockNumber;
        address[] users;
    }

    mapping(bytes32 => Commitment) commitmentsData;

    function deploy(address template, bytes32 salt, address admin) external returns (address proxyAddr) {
        require(checkCommmitment(salt, keccak256(abi.encodePacked(msg.sender, admin))));
        // Create our minimal proxy contract using CREATE2 (OpenZeppelin refers to this as a "clone")
        proxyAddr = Clones.cloneDeterministic(template, salt, 0);

        // Set the admin to the EOA address that deployed it
        (bool success,) = proxyAddr.call(abi.encodeWithSignature("initialise(address)", admin));
        require(success, "Failed to initialise proxy contract");

        // Return the address of the proxy contract
        return proxyAddr;
    }

    function createCommitment(bytes32 salt, bytes32 commit) external {
        // Add a new commitment for the user link it to the block number
        commitmentsData[salt].blockNumber[msg.sender][commit] = block.number;
        // Push the user to the list of users for this commitment
        commitmentsData[salt].users.push(msg.sender);
    }

    function checkCommmitment(bytes32 salt, bytes32 commit) internal view returns (bool) {
        // Check if the user has already made a commitment
        if (commitmentsData[salt].blockNumber[msg.sender][commit] == 0) {
            return false;
        }

        address validUser;
        uint256 lowestBlockNumber;
        // The "legitimate" user should the lowest block number
        for (uint256 i = 0; i < commitmentsData[salt].users.length; i++) {
            uint256 tmpBlockNumber = commitmentsData[salt].blockNumber[commitmentsData[salt].users[i]][commit];
            if (tmpBlockNumber < lowestBlockNumber) {
                validUser = commitmentsData[salt].users[i];
            }
        }

        // Check if the msg.sender is the legitimate user
        if (validUser != msg.sender) {
            return false;
        }
    }

    // Helper function to retrieve the address of the proxy contract
    function retrieveAddress(address template, bytes32 salt) external view returns (address proxyAddr) {
        // Check that the address of the proxy contract is computed correctly
        proxyAddr = Clones.predictDeterministicAddress(template, salt);
        return proxyAddr;
    }
}
