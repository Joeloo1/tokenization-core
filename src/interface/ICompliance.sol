// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICompliance {
    function canTransfer(address from, address to, uint256 amount) external view returns (bool allowed, bytes32 reason);
}
