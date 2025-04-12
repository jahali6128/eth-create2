// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";


contract FactoryCREATE2 {


    modifier lock() {
        _;
        assembly {
            tstore(0,1)
        }
    }

    mapping(bytes32 => bool) commitments;


    function deploy(address template, bytes32 salt, address admin) external returns (address proxyAddr) {
        // Create our minimal proxy contract using CREATE2 (OpenZeppelin refers to this as a "clone")
        proxyAddr = Clones.cloneDeterministic(template, salt, 0);

        // Set the admin to the EOA address that deployed it
        (bool success,) = proxyAddr.call(abi.encodeWithSignature("initialise(address)", admin));
        require(success, "Failed to initialise proxy contract");

        // Return the address of the proxy contract
        return proxyAddr;
    }

    // Helper function to retrieve the address of the proxy contract
    function retrieveAddress(address template, bytes32 salt) external view returns (address proxyAddr) {
        // Check that the address of the proxy contract is computed correctly
        proxyAddr = Clones.predictDeterministicAddress(template, salt);
        return proxyAddr;
    }

}