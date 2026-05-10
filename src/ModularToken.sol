// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IdentityRegistry} from "./IdentityRegistry.sol";
import {Compliance} from "./Compliance.sol";

/**
 * @title ModularToken
 * @notice Token with identity + compliance checks
 */
contract ModularToken {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);

    IdentityRegistry public identity;
    Compliance public compliance;

    mapping(address => uint256) public balanceOf;

    address public owner;
    uint256 public totalSupply;

    constructor(address _identity, address _compliance) {
        identity = IdentityRegistry(_identity);
        compliance = Compliance(_compliance);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "Not owner");
    }

    /**
     * @notice Mint tokens to a user
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address");
        require(identity.isVerified(to), "User not verified");
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
    }

    /**
     * @notice Transfer tokens with checks
     */
    function transfer(address from, address to, uint256 amount) external {
        require(to != address(0), "Zero address");
        require(identity.isVerified(msg.sender), "Sender not verified");
        require(identity.isVerified(to), "Receiver not verified");

        // ✅ new signature — from, to, amount, returns (bool, bytes32)
        (bool allowed, bytes32 reason) = compliance.canTransfer(from, to, amount);
        require(allowed, string(abi.encodePacked(reason)));

        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }
}
