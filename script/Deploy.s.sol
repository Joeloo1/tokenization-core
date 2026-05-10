// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {Compliance} from "../src/Compliance.sol";
import {ModularToken} from "../src/ModularToken.sol";

contract Deploy is Script {
    function run() external returns (IdentityRegistry identity, Compliance compliance, ModularToken token) {
        vm.startBroadcast();

        // 1. Deploy Identity Registry
        identity = new IdentityRegistry();

        // 2. Deploy Compliance (set max transfer limit)
        compliance = new Compliance(1000, 0, address(identity));

        // 3. Deploy Token (connect both systems)
        token = new ModularToken(address(identity), address(compliance));

        vm.stopBroadcast();
    }
}
