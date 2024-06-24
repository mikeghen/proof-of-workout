// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClubPool} from "../src/ClubPool.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract ClubPoolTest is Test {
    MockUSDC usdc;
    ClubPool clubPool;
    ClubPool clubPool2;
    address owner;
    address alice;
    address bob;
    address charlie;
    uint256 stakeAmount = 50 * 1e6;

    function setUp() public {
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);
        charlie = address(0x3);

        usdc = new MockUSDC();
        clubPool = new ClubPool(address(usdc), 12 weeks, owner, stakeAmount);
        
        clubPool2 = new ClubPool(address(usdc), 6 weeks, owner, stakeAmount);

        usdc.mint(alice, 100 * 1e6);
        usdc.mint(bob, 100 * 1e6);
        usdc.mint(charlie, 100 * 1e6);

    }

    modifier alice_and_bob() {
        vm.startPrank(alice);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();
        _;
    }

    function testJoinClub() public {
        vm.startPrank(alice);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        (uint256 stake, bool slashed, bool claimed, uint256 slashVotes) = clubPool.members(alice);

        assertEq(stake, stakeAmount);
        assertFalse(slashed);
        assertFalse(claimed);
        assertEq(slashVotes, 0);
    }

    function testStartClub() public {
        clubPool.startClub();

        assertTrue(clubPool.started());
    }

    function testProposeSlash() alice_and_bob public {

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        (, bool slashed, , uint256 slashVotes) = clubPool.members(bob);
        assertEq(slashVotes, 1);
        assertFalse(slashed);
    }

    function testVetoSlash() alice_and_bob public {

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        vm.prank(owner);
        clubPool.vetoSlash(bob);

        (, bool slashed, , uint256 slashVotes) = clubPool.members(bob);
        assertEq(slashVotes, 0);
        assertFalse(slashed);
    }

    function testClaimRewards() alice_and_bob public {
        uint256 initialBalance = usdc.balanceOf(alice);

        clubPool.startClub();
        vm.warp(block.timestamp + 12 weeks);

        vm.prank(alice);
        clubPool.claim();

        (uint256 stake,, bool claimed,) = clubPool.members(alice);
        assertEq(stake, 0);
        assertTrue(claimed);
        assertEq(usdc.balanceOf(alice), initialBalance + stakeAmount);
    }

    function testCannotClaimTwice() alice_and_bob public {
        uint256 initialBalance = usdc.balanceOf(alice);

        clubPool.startClub();
        vm.warp(block.timestamp + 12 weeks);

        vm.prank(alice);
        clubPool.claim();

        vm.expectRevert("Not a member");
        vm.prank(alice);
        clubPool.claim();

        assertEq(usdc.balanceOf(alice), initialBalance + stakeAmount);
    }

    function testClaimNonMember() alice_and_bob public {
        clubPool.startClub();
        vm.warp(block.timestamp + 12 weeks);

        vm.expectRevert("Not a member");
        vm.prank(charlie);
        clubPool.claim();
    }

    function testProposeAndSlash() alice_and_bob public {
        vm.startPrank(charlie);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        clubPool.startClub();

        vm.prank(alice);
        clubPool.proposeSlash(bob);

        vm.prank(charlie);
        clubPool.proposeSlash(bob);

        (, bool slashedBob,, uint256 slashVotesBob) = clubPool.members(bob);
        assertTrue(slashedBob);
        assertEq(slashVotesBob, 2);

        uint256 share = stakeAmount / 2;
        (uint256 stakeAlice,,,) = clubPool.members(alice);
        (uint256 stakeCharlie,,,) = clubPool.members(charlie);
        assertEq(stakeAlice, stakeAmount + share);
        assertEq(stakeCharlie, stakeAmount + share);
    }

    function testRecordActivity() public {
        vm.prank(owner);
        clubPool.recordActivity(1, 101, 5000, 3600);
    }
}
