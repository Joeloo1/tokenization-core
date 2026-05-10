// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICompliance} from "./interface/ICompliance.sol";
import {IIdentityRegistry} from "./interface/IIdentityRegistry.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Compliance
 * @notice Defines transfer rules
 */
contract Compliance is ICompliance, Ownable2Step {
    // ERROR
    error ZeroAddress();
    error AlreadyFrozen();
    error NotFrozen();
    error BpsOverHundredPercent();

    // Reason code
    bytes32 public constant REASON_OK = bytes32(0);
    bytes32 public constant REASON_FROZEN = "FROZEN";
    bytes32 public constant REASON_EXCEEDS_MAX = "EXCEEDS_MAX_TRANSFER";
    bytes32 public constant REASON_EXCEEDS_HOLD = "EXCEEDS_MAX_HOLDNG";
    bytes32 public constant REASON_NOT_VERIFIED = "NOT_VERIFIED";

    uint256 public maxTransferAmount;
    uint256 public maxHoldingBps;
    address public token;
    IIdentityRegistry public identityRegistry;

    mapping(address => bool) public frozen;

    // EVENT
    event MaxAmountUpdated(uint256 oldMax, uint256 newMax);
    event MaxBpsHoldingUpdated(uint256 oldBps, uint256 newBps);
    event AddressFrozen(address indexed addr, bool frozen);
    event TokenSet(address indexed token);
    event IdentityRegistrySet(address indexed registry);

    constructor(uint256 _maxTransferAmount, uint256 _maxHoldingBps, address _identityRegistry) Ownable(msg.sender) {
        if (_identityRegistry == address(0)) revert ZeroAddress();

        maxTransferAmount = _maxTransferAmount;
        maxHoldingBps = _maxHoldingBps;
        identityRegistry = IIdentityRegistry(_identityRegistry);

        emit IdentityRegistrySet(_identityRegistry);
    }

    // modifier onlyOwner() {
    //     _onlyOwner();
    //     _;
    // }
    //
    // function _onlyOwner() internal view {
    //     require(msg.sender == owner, "Not owner");
    // }
    //

    function setToken(address _token) external onlyOwner {
        if (_token == address(0)) revert ZeroAddress();

        token = _token;

        emit TokenSet(_token);
    }

    function setMaxAmount(uint256 newMax) external onlyOwner {
        emit MaxAmountUpdated(maxTransferAmount, newMax);

        maxTransferAmount = newMax;
    }

    function setMaxHoldingBps(uint256 newBps) external onlyOwner {
        if (newBps > 10_000) revert BpsOverHundredPercent();

        emit MaxBpsHoldingUpdated(maxHoldingBps, newBps);

        maxHoldingBps = newBps;
    }

    function freezeAddress(address addr, bool _frozen) external onlyOwner {
        if (_frozen && frozen[addr]) revert AlreadyFrozen();

        if (!_frozen && !frozen[addr]) revert NotFrozen();

        frozen[addr] = _frozen;

        emit AddressFrozen(addr, _frozen);
    }

    function setIdentityRegistry(address _registry) external onlyOwner {
        if (_registry == address(0)) revert ZeroAddress();

        identityRegistry = IIdentityRegistry(_registry);

        emit IdentityRegistrySet(_registry);
    }

    /**
     * @notice Check if a transfer is allowed
     * @return allowed  true if transfer is permitted
     * @return reason   bytes32 code; zero bytes if allowed
     */
    // function canTransfer(uint256 amount) external view returns (bool) {
    //     return amount <= maxAmount;
    // }
    //
    // function setMaxAmount(uint256 _maxAmount) external onlyOwner {
    //     maxAmount = _maxAmount;
    //     emit MaxAmountUpdated(_maxAmount);
    // }
    //

    function canTransfer(address from, address to, uint256 amount)
        external
        view
        override
        returns (bool allowed, bytes32 reason)
    {
        // check is the address is FROZEN
        if (frozen[from] || frozen[to]) return (false, REASON_FROZEN);

        // Identity check. Both addresses must be verified
        if (!identityRegistry.isVerified(from) || !identityRegistry.isVerified(to)) {
            return (false, REASON_NOT_VERIFIED);
        }

        // Max Transfer amount check
        if (amount > maxTransferAmount) return (false, REASON_EXCEEDS_MAX);

        // Max Holding Check
        if (token != address(0) && maxHoldingBps > 0) {
            uint256 supply = IERC20(token).totalSupply();
            uint256 afterBalance = IERC20(token).balanceOf(to) + amount;

            if (afterBalance * 10_000 > supply * maxHoldingBps) return (false, REASON_EXCEEDS_HOLD);
        }

        return (true, REASON_OK);
    }
}
