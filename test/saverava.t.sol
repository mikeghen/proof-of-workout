// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClubPool} from "../src/saverava.sol";
import {MockUSDC} from "../src/mocks/mockUsdc.sol";
import {ClubPoolFactory} from "../src/saveravaFactory.sol";

contract ClubPoolTest is Test {
    MockUSDC usdc;
    ClubPool clubPool;
    address owner;
    address alice;
    address bob;
    address charlie;
    ClubPoolFactory factory;

    function setUp() public {
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);
        charlie = address(0x3);

        usdc = new MockUSDC();
        clubPool = new ClubPool(address(usdc), 12 weeks, owner);

        factory = new ClubPoolFactory();

        usdc.mint(alice, 100 * 1e6);
        usdc.mint(bob, 100 * 1e6);
        usdc.mint(charlie, 100 * 1e6);

        // Create a ClubPool instance using the factory
        address clubPoolAddress = factory.createClubPool(address(usdc), 12 weeks, owner);
        clubPool = ClubPool(clubPoolAddress);
    }

    function testJoinClub() public {
        vm.prank(alice);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(alice);
        clubPool.join();

        (uint256 stake, bool slashed, uint256 slashVotes) = clubPool.members(alice);
        assertEq(stake, 50 * 1e6);
        assertFalse(slashed);
        assertEq(slashVotes, 0);
    }

    function testStartClub() public {
        clubPool.startClub();

        assertTrue(clubPool.started());
    }

    function testProposeSlash() public {
        vm.prank(alice);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(alice);
        clubPool.join();

        vm.prank(bob);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(bob);
        clubPool.join();

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        (uint256 stake, bool slashed, uint256 slashVotes) = clubPool.members(bob);
        assertEq(slashVotes, 1);
        assertFalse(slashed);
    }

    function testVetoSlash() public {
        vm.prank(alice);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(alice);
        clubPool.join();

        vm.prank(bob);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(bob);
        clubPool.join();

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        vm.prank(owner);
        clubPool.vetoSlash(bob);

        (uint256 stake, bool slashed, uint256 slashVotes) = clubPool.members(bob);
        assertEq(slashVotes, 0);
        assertFalse(slashed);
    }

    function testClaimRewards() public {
        vm.prank(alice);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(alice);
        clubPool.join();

        vm.prank(bob);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(bob);
        clubPool.join();

        clubPool.startClub();
        vm.warp(block.timestamp + 12 weeks);

        vm.prank(alice);
        clubPool.claim();

        (uint256 stake, bool slashed, uint256 slashVotes) = clubPool.members(alice);
        assertEq(stake, 0);

        assertEq(usdc.balanceOf(alice), 50 * 1e6);
    }

    function testProposeAndSlash() public {
        vm.prank(alice);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(alice);
        clubPool.join();

        vm.prank(bob);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(bob);
        clubPool.join();

        vm.prank(charlie);
        usdc.approve(address(clubPool), 50 * 1e6);
        vm.prank(charlie);
        clubPool.join();

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        vm.prank(charlie);
        clubPool.proposeSlash(bob);

        (uint256 stakeBob, bool slashedBob, uint256 slashVotesBob) = clubPool.members(bob);
        assertTrue(slashedBob);
        assertEq(slashVotesBob, 2);

        uint256 share = 50 * 1e6 / 2;
        (uint256 stakeAlice,,) = clubPool.members(alice);
        (uint256 stakeCharlie,,) = clubPool.members(charlie);
        assertEq(stakeAlice, 50 * 1e6 + share);
        assertEq(stakeCharlie, 50 * 1e6 + share);
    }

    function testRecordActivity() public {
        vm.prank(owner);
        clubPool.recordActivity(1, 101, 5000, 3600);
    }
}
