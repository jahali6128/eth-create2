// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FactoryCREATE2} from "../src/FactoryCreate2.sol";
import {Template} from "../src/Template.sol";
import {Call} from "../src/Call.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

contract Create2Test is Test {
    FactoryCREATE2 factory;
    Template template;
    Call callSc;

    address dev = makeAddr("dev");
    address user = makeAddr("user");
    address proxy;
    bytes32 salt;

    // This function will run before each test
    function setUp() public {
        factory = new FactoryCREATE2();
        template = new Template();

        // We use a random salt/hash this time
        salt = keccak256(abi.encodePacked("foo"));

        // Create our minimal proxy contract using CREATE2 (OpenZeppelin refers to this as a "clone")
        // proxy = Clones.cloneDeterministic(address(template), salt, 0);
        proxy = factory.deploy(address(template), salt, dev);
    }

    // Check that the address of the proxy contract is computed correctly
    function test_checkAddress() public view {
        // Check there is code in our proxy contract - should be 45 bytes
        assertEq(proxy.code.length, 45, "Proxy contract is empty!");

        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", // first part of the bytecode
            address(template), // address of the contract to clone
            hex"5af43d82803e903d91602b57fd5bf3" // last part of the bytecode
        );

        address create2Address = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(factory), // address of the Factory contract (the sender)
                            salt, // salt
                            keccak256(bytecode) // bytecode
                        )
                    )
                )
            )
        );

        assertEq(create2Address, address(proxy), "Proxy address not computed correctly");
    }

    function test_initialise() public {
        // Check that the admin is NOT set
        assertEq(template.admin(), address(0), "Admin is already set - this should NOT be the case!");

        // Set the admin to the dev address
        template.initialise(dev);
        // Check that the admin is set
        assertEq(template.admin(), dev, "Admin is not set!");

        // Try to set the admin again - should FAIL this time
        vm.expectRevert("Admin is already set!");
        template.initialise(user);
    }

    // Same test as test_initialise() but using the proxy contract
    function test_initialiseProxy() public {
        // Check that the admin is NOT set
        assertEq(template.admin(), address(0), "Admin is already set - this should NOT be the case!");

        // Set the admin to the dev address
        // (bool success,) = proxy.call(abi.encodeWithSignature("initialise(address)", dev));
        // assertEq(success, true, "Initialise failed!");

        // Check that the admin is set
        (bool success_1, bytes memory data) = proxy.call(abi.encodeWithSignature("admin()"));
        assertEq(success_1, true, "Admin retrieval failed!");
        assertEq(abi.decode(data, (address)), dev, "Admin is not set!");
    }

    function test_storeSbomUrl() public {
        // Set the admin to the dev address & impersonate the dev user
        // template.initialise(dev);

        // Store the SBOM URL
        vm.prank(dev);
        template.storeSbomUrl("https://example.com/sbom");
        // Check that the SBOM URL is stored correctly & can be retrieved
        assertEq(template.retrieveSbomUrl(), "https://example.com/sbom", "SBOM URL not stored correctly!");

        // Try to store the SBOM URL as a non-admin user - should FAIL this time
        vm.prank(user);
        vm.expectRevert("Not an Admin account!");
        template.storeSbomUrl("https://malicious.com/sbom"); //
    }

    function test_storeSbomUrlProxy() public {
        // Set the admin to the dev address & impersonate the dev user
        // template.initialise(dev);
        // (bool initialised,) = proxy.call(abi.encodeWithSignature("initialise(address)", dev));
        // assertEq(initialised, true, "Initialise failed!");
        
        // Store the SBOM URL

        bytes32 commitment = keccak256(abi.encodePacked(dev, salt));
        factory.createCommitment(salt, commitment);

        vm.prank(dev);
        (bool success,) = proxy.call(abi.encodeWithSignature("storeSbomUrl(string)", "https://example.com/sbom"));
        assertEq(success, true, "Store SBOM URL failed!");

        // Check that the SBOM URL is stored correctly & can be retrieved
        (bool success_1, bytes memory data) = proxy.call(abi.encodeWithSignature("retrieveSbomUrl()"));
        assertEq(success_1, true, "Retrieve SBOM URL failed!");
        assertEq(abi.decode(data, (string)), "https://example.com/sbom", "SBOM URL not stored correctly!");

        // Try to store the SBOM URL as a non-admin user - should FAIL this time
        vm.prank(user);
        // vm.expectRevert("Not an Admin account!");
        (bool success_2,) = proxy.call(abi.encodeWithSignature("storeSbomUrl(string)", "https://malicious.com/sbom"));
        // This time we expect the call to fail
        assertEq(success_2, false, "Store SBOM URL should have failed!");
    }


    function test_storeSbomUrlCall() public {
        callSc = new Call();
        (bool success,) = proxy.call(abi.encodeWithSignature("initialise(address)", address(callSc)));
        // template.initialise(address(callSc));
        require(success, "Failed to initialise proxy contract");

        address callScAddress = callSc._retrieveAddress(address(factory), address(template), salt);
        assertEq(callScAddress, address(proxy), "Proxy address not computed correctly");

        // vm.prank(dev);
        callSc.setSBOM(address(factory), address(template), salt, "https://example.com/sbom");
    }
}
