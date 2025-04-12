// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract Call {
    function setSBOM(
        address factory,
        address template,
        bytes32 salt,
        string memory url
    ) external {
        address proxy = _retrieveAddress(factory, template, salt);
        (bool success, ) = proxy.call(
            abi.encodeWithSignature("storeSbomUrl(string)", url)
        );

        require(success, "Failed to store SBOM");
    }

    function getSbom(
        address factory,
        address template,
        bytes32 salt
    ) external returns (string memory) {
        address proxy = _retrieveAddress(factory, template, salt);
        (bool success, bytes memory data) = proxy.call(
            abi.encodeWithSignature("getSbomUrl()")
        );
        require(success, "Failed to retrieve SBOM url");

        // Decode and return back to user
        return abi.decode(data, (string));
    }

    // Helper function to retrieve the address of the proxy contract
    function _retrieveAddress(
        address factory,
        address template,
        bytes32 salt
    ) public pure returns (address) {
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
                            factory,
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
