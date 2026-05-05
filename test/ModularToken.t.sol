// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {Compliance} from "../src/Compliance.sol";
import {ModularToken} from "../src/ModularToken.sol";

contract ModularTokenTest is Test {
    IdentityRegistry identity;
    Compliance compliance;
    ModularToken token;

    address alice = address(1);
    address bob = address(2);

    function setUp() public {
        identity = new IdentityRegistry();
        compliance = new Compliance(1000);
        token = new ModularToken(address(identity), address(compliance));
    }

    function testMintFailsIfNotVerified() public {
        vm.expectRevert();
        token.mint(alice, 100);
    }

    function testMintWorksIfVerified() public {
        identity.verify(alice);

        token.mint(alice, 100);

        assertEq(token.balanceOf(alice), 100);
    }

    function testTransferFailsIfReceiverNotVerified() public {
        identity.verify(address(this));

        token.mint(address(this), 100);

        vm.expectRevert();
        token.transfer(alice, 10);
    }

    function testTransferWorksWhenBothVerified() public {
        identity.verify(address(this));
        identity.verify(alice);

        token.mint(address(this), 100);

        token.transfer(alice, 10);

        assertEq(token.balanceOf(alice), 10);
    }

    function testTransferFailsIfAboveComplianceLimit() public {
        identity.verify(address(this));
        identity.verify(alice);

        token.mint(address(this), 2000);

        vm.expectRevert();
        token.transfer(alice, 1500);
    }
}
