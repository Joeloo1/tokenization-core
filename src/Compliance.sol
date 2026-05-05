// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Compliance
 * @notice Defines transfer rules
 */
contract Compliance {
    uint256 public maxAmount;

    constructor(uint256 _maxAmount) {
        maxAmount = _maxAmount;
    }

    /**
     * @notice Check if transfer is allowed
     */
    function canTransfer(uint256 amount) external view returns (bool) {
        return amount <= maxAmount;
    }
}
