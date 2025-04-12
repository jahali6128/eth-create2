// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";


// To-do - implement the commitment step 

contract FactoryCREATE2 {
    function deploy(address template, bytes32 salt, address admin)
        external
        returns (address proxyAddr)
    {
        // Create our minimal proxy contract using CREATE2 (OpenZeppelin refers to this as a "clone")
        proxyAddr = Clones.cloneDeterministic(template, salt, 0);

        // Set the admin to the EOA address that deployed it
        (bool success, ) = proxyAddr.call(
            abi.encodeWithSignature("initialise(address)", admin)
        );
        require(success, "Failed to initialise proxy contract");

        // Return the address of the proxy contract
        return proxyAddr;
    }

    // Helper function to retrieve the address of the proxy contract
    function retrieveAddress(address template, bytes32 salt)
        external
        view
        returns (address)
    {
        // Check that the address of the proxy contract is computed correctly

        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", // first part of the bytecode
            template, // address of the contract to clone
            hex"5af43d82803e903d91602b57fd5bf3" // last part of the bytecode
        );

        address proxyAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(bytecode)
                        )
                    )
                )
            )
        );

        return proxyAddr;
    }
}
