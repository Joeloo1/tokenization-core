// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IIdentityRegistry} from "./interface/IIdentityRegistry.sol";
import {ICompliance} from "./interface/ICompliance.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ModularToken
 * @notice Token with identity + compliance checks
 */
contract ModularToken is ERC20, Ownable2Step {
    //error
    error ZeroAddress();
    error NotVerified();
    error TransferNotAllowed(bytes32 reason);

    // event Transfer(address indexed from, address indexed to, uint256 amount);
    // event Mint(address indexed to, uint256 amount);

    IIdentityRegistry public identityRegistry;
    ICompliance public compliance;

    event IdentityRegistrySet(address indexed registry);
    event ComplianceSet(address indexed compliance);

    /**
     * mapping(address => uint256) public balanceOf;
     *
     * address public owner;
     * uint256 public totalSupply;
     */

    constructor(address _identityRegistry, address _compliance) ERC20("ModularToken", "MTK") Ownable(msg.sender) {
        if (_identityRegistry == address(0)) revert ZeroAddress();
        if (_compliance == address(0)) revert ZeroAddress();

        identityRegistry = IIdentityRegistry(_identityRegistry);
        compliance = ICompliance(_compliance);
        // owner = msg.sender;
    }

    /**
     * modifier onlyOwner() {
     *     _onlyOwner();
     *     _;
     * }
     *
     * function _onlyOwner() internal view {
     *     require(msg.sender == owner, "Not owner");
     * }
     */

    /**
     * @notice Mint tokens to a user
     */
    function mint(address to, uint256 amount) external onlyOwner {
        // require(to != address(0), "Zero address");
        // require(identity.isVerified(to), "User not verified");

        if (to == address(0)) revert ZeroAddress();
        if (!identityRegistry.isVerified(to)) revert NotVerified();

        _mint(to, amount);

        /**
         * balanceOf[to] += amount;
         * totalSupply += amount;
         *
         * emit Mint(to, amount);
         */
    }

    function burn(uint256 amount) external {
        if (!identityRegistry.isVerified(msg.sender)) revert NotVerified();

        _burn(msg.sender, amount);

        /**
         * require(balanceOf[msg.sender] >= amount, "Insufficient balance");
         *
         * balanceOf[msg.sender] -= amount;
         * totalSupply -= amount;
         */
    }

    /**
     * @notice Transfer tokens with checks
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        (bool allowed, bytes32 reason) = compliance.canTransfer(msg.sender, to, amount);

        if (!allowed) revert TransferNotAllowed(reason);
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        (bool allowed, bytes32 reason) = compliance.canTransfer(from, to, amount);

        if (!allowed) revert TransferNotAllowed(reason);
        return super.transferFrom(from, to, amount);
    }

    function setCompliance(address _compliance) external onlyOwner {
        if (_compliance == address(0)) revert ZeroAddress();

        compliance = ICompliance(_compliance);

        emit ComplianceSet(_compliance);
    }

    function setIdentityRegistry(address _registry) external onlyOwner {
        if (_registry == address(0)) revert ZeroAddress();

        identityRegistry = IIdentityRegistry(_registry);

        emit IdentityRegistrySet(_registry);
    }

    /**
     * function transfer(address from, address to, uint256 amount) external {
     *     require(to != address(0), "Zero address");
     *     require(identity.isVerified(msg.sender), "Sender not verified");
     *     require(identity.isVerified(to), "Receiver not verified");
     *
     *     // ✅ new signature — from, to, amount, returns (bool, bytes32)
     *     (bool allowed, bytes32 reason) = compliance.canTransfer(from, to, amount);
     *     require(allowed, string(abi.encodePacked(reason)));
     *
     *     require(balanceOf[msg.sender] >= amount, "Insufficient balance");
     *
     *     balanceOf[msg.sender] -= amount;
     *     balanceOf[to] += amount;
     *
     *     emit Transfer(msg.sender, to, amount);
     * }
     */
}
