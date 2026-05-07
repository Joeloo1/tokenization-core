// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IIdentityRegistry} from "./interface/IIdentityRegistry.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IdentityRegistry is IIdentityRegistry, Ownable2Step {
    // ERRORS
    error ZeroAddress();
    error NotAgent();
    error AlreadyVerified();
    error NotVerified();
    error AlreadyAgent();
    error NotAnAgent();
    error CannotVerifySelf();
    // error NotOwner();

    // EVENTS
    event Verified(address indexed user);
    event Revoked(address indexed user);
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);

    mapping(address => bool) private _isVerified;
    mapping(address => bool) private _agents;

    /*
      address public owner;

      // constructor() {
          owner = msg.sender;
      }

      modifier onlyOwner() {
          _onlyOwner();
          _;
      }

      function _onlyOwner() internal view {
          if (msg.sender != owner) revert NotOwner();
          // require(msg.sender == owner, "Not owner");
      }
    */

    modifier onlyAgent() {
        _onlyAgent();
        _;
    }

    function _onlyAgent() internal view {
        if (!_agents[msg.sender] && msg.sender != owner()) revert NotAgent();
    }

    constructor() Ownable(msg.sender) {}

    function verify(address user) external override onlyAgent {
        // require(user == address(0), "Zero address");
        // require(!isVerified[user], "Already Verified");
        if (user == address(0)) revert ZeroAddress();
        if (user == msg.sender) revert CannotVerifySelf();
        if (_isVerified[user]) revert AlreadyVerified();

        _isVerified[user] = true;
        emit Verified(user);
    }

    function revoke(address user) external override onlyAgent {
        // require(user == address(0), "Zero address");
        if (user == address(0)) revert ZeroAddress();
        if (!_isVerified[user]) revert NotVerified();

        _isVerified[user] = false;
        emit Revoked(user);
    }

    function isVerified(address user) external view override returns (bool) {
        return _isVerified[user];
    }

    function isAgent(address account) external view override returns (bool) {
        return _agents[account];
    }

    /* Agent Management */
    function addAgent(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        if (_agents[account]) revert AlreadyAgent();

        _agents[account] = true;
        emit AgentAdded(account);
    }

    function removeAgent(address account) external onlyOwner {
        if (!_agents[account]) revert NotAnAgent();

        _agents[account] = false;
        emit AgentRemoved(account);
    }
    /*
      function transferOwnership(address newOwner) external onlyOwner {
          // require(newOwner == address(0), "Zero address");
          if (user == address(0)) revert ZeroAddress();

          owner = newOwner;
      }
    */
}
