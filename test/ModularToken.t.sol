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

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

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
        identity.verify(alice);

        token.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 10);
    }

    function testTransferWorksWhenBothVerified() public {
        identity.verify(alice);
        identity.verify(bob);

        token.mint(alice, 100);

        vm.prank(alice);
        token.transfer(bob, 10);

        assertEq(token.balanceOf(bob), 10);
    }

    function testTransferFailsIfAboveComplianceLimit() public {
        identity.verify(alice);
        identity.verify(bob);

        token.mint(alice, 2000);

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1500);
    }
}
