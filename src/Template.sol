// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Template {
    string SBOM_URL;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an Admin account!");
        _;
    }

    // fallback() external {
    //     revert("Function does not exist!");
    // }

    // Set the admin to the EOA address that deployed it
    // Must be run only once to set permissions
    function initialise(address _admin) external {
        require(admin == address(0), "Admin is already set!");
        admin = _admin;
    }

    function storeSbomUrl(string memory url) external onlyAdmin {
        SBOM_URL = url;
    }

    function retrieveSbomUrl() external view returns (string memory) {
        return SBOM_URL;
    }
}
