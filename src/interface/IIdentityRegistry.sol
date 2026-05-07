// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IIdentityRegistry {
    function verify(address user) external;
    function revoke(address user) external;
    function isVerified(address user) external view returns (bool);
    function isAgent(address account) external view returns (bool);
}
