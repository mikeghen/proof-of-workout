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
        clubPool = new ClubPool(address(usdc), 12 weeks, 100, owner, stakeAmount);
        clubPool2 = new ClubPool(address(usdc), 12 weeks, 100, owner, stakeAmount);

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

    function testRecordRun() public alice_and_bob {
        clubPool.startClub();

        vm.prank(alice);
        clubPool.recordRun(alice, 10);

        (uint256 miles, uint256 timestamp) = clubPool.getRunData(0);
        assertEq(miles, 10);
        assertEq(timestamp, block.timestamp);
    }

    function testRecordRunsForWeek() public alice_and_bob {
        clubPool.startClub();

        // Record the first run for Alice
        vm.warp(block.timestamp + 1 days); // Warp forward by 1 day
        vm.prank(alice);
        clubPool.recordRun(alice, 10);
        uint256 tokenId1 = clubPool.totalSupply() - 1; // Get the latest token ID

        // Record a run for Bob
        vm.warp(block.timestamp + 2 days); // Warp forward by 2 more days
        vm.prank(bob);
        clubPool.recordRun(bob, 5);

        // Record the second run for Alice
        vm.warp(block.timestamp + 3 days); // Warp forward by 3 more days
        vm.prank(alice);
        clubPool.recordRun(alice, 15);
        uint256 tokenId2 = clubPool.totalSupply() - 1; // Get the latest token ID

        // Record the third run for Alice
        vm.warp(block.timestamp + 4 days); // Warp forward by 4 more days
        vm.prank(alice);
        clubPool.recordRun(alice, 20);
        uint256 tokenId3 = clubPool.totalSupply() - 1; // Get the latest token ID

        // Check total miles for Alice
        uint256 totalMiles = 0;
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = tokenId1;
        tokenIds[1] = tokenId2;
        tokenIds[2] = tokenId3;
        for (uint256 i = 0; i < 3; i++) {
            (uint256 miles,) = clubPool.getRunData(tokenIds[i]);
            totalMiles += miles;
        }

        // Assert total miles for Alice
        assertEq(totalMiles, 45);

        // Check ownership of Alice's NFTs
        for (uint256 i = 0; i < 3; i++) {
            assertEq(clubPool.ownerOf(tokenIds[i]), alice);
        }
    }

    function testAutoSlash() public alice_and_bob {
        clubPool.startClub();

        // Alice records a run of 50 miles (meets requirement)
        vm.prank(alice);
        clubPool.recordRun(alice, 50);

        // Bob records a run of 4 miles
        vm.prank(bob);
        clubPool.recordRun(bob, 4);

        // Warp forward by 7 days
        vm.warp(block.timestamp + 7 days);

        // Alice records a run of 50 miles (meets requirement)
        vm.prank(alice);
        clubPool.recordRun(alice, 50);

        // Manually trigger a check for slashing
        vm.prank(owner);
        clubPool.checkSlash(alice);
        clubPool.checkSlash(bob);

        (, bool slashedAlice,,) = clubPool.members(alice);
        assertFalse(slashedAlice);

        (, bool slashedBob,,) = clubPool.members(bob);
        assertTrue(slashedBob);
    }

    function testVetoSlash() public alice_and_bob {
        clubPool.startClub();

        vm.prank(bob);
        clubPool.recordRun(bob, 4);

        // Warp forward by 7 days
        vm.warp(block.timestamp + 7 days);

        // Manually trigger a check for slashing
        vm.prank(owner);
        clubPool.checkSlash(bob);

        vm.prank(owner);
        clubPool.vetoSlash(bob);

        (, bool slashed,,) = clubPool.members(bob);
        assertFalse(slashed);
    }

    function testStakeAfterSlash() public alice_and_bob {
    clubPool.startClub();

    // Alice records a run of 50 miles (meets requirement)
    vm.prank(alice);
    clubPool.recordRun(alice, 50);

    // Bob records a run of 4 miles
    vm.prank(bob);
    clubPool.recordRun(bob, 4);

    // Warp forward by 7 days
    vm.warp(block.timestamp + 7 days);
    
    // Manually trigger a check for slashing
    vm.prank(owner);
    clubPool.checkSlash(bob);

    // Check that Bob is slashed
    (, bool slashedBob,,) = clubPool.members(bob);
    assertTrue(slashedBob);

    // Calculate expected stake increase for Alice
    uint256 totalMembers = clubPool.getMemberCount();
    uint256 expectedStakeIncrease = stakeAmount / (totalMembers - 1);

    // Check that Alice's stake increased
    (uint256 stake,,,) = clubPool.members(alice);
    assertEq(stake, stakeAmount + expectedStakeIncrease);
}

    function testClaimRewards() public alice_and_bob {
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

    function testCannotClaimTwice() public alice_and_bob {
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

    function testClaimNonMember() public alice_and_bob {
        clubPool.startClub();
        vm.warp(block.timestamp + 12 weeks);

        vm.expectRevert("Not a member");
        vm.prank(charlie);
        clubPool.claim();
    }

    function testYieldAmountAfterEndTime() public alice_and_bob {
        clubPool.startClub();
        
        // Warp to after the end time
        vm.warp(block.timestamp + 13 weeks);

        uint256 expectedYield = (stakeAmount * 20 * 12 weeks) / (100 * 365 days);
        uint256 actualYield = clubPool.yieldAmount(alice);
        
        assertEq(actualYield, expectedYield, "Incorrect yield amount after end time");
        
        // If the assertion fails, print the values for debugging
        if (actualYield != expectedYield) {
            console.log("Expected yield:", expectedYield);
            console.log("Actual yield:", actualYield);
        }
    }

    function testRewardAmountWithMultipleSlashedMembers() public {
        // Add Alice, Bob, and Charlie to the club
        vm.startPrank(alice);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        vm.startPrank(charlie);
        usdc.approve(address(clubPool), stakeAmount);
        clubPool.join();
        vm.stopPrank();

        clubPool.startClub();

        // Manually slash Bob and Charlie
        vm.prank(bob);
        clubPool.recordRun(bob, 4);
        vm.prank(charlie);
        clubPool.recordRun(charlie, 4);
        vm.warp(block.timestamp + 7 days);
        vm.prank(owner);
        clubPool.checkSlash(bob);
        clubPool.checkSlash(charlie);

        uint256 expectedReward = (stakeAmount * 2) / 3; // Two-thirds of the stake amount as there are three members
        uint256 actualReward = clubPool.rewardAmount();
        
        assertEq(actualReward, expectedReward, "Incorrect reward amount with multiple slashed members");
        
        // If the assertion fails, print the values for debugging
        if (actualReward != expectedReward) {
            console.log("Expected reward:", expectedReward);
            console.log("Actual reward:", actualReward);
        }
    }

    function testRecordActivity() public {
        vm.prank(owner);
        clubPool.recordActivity(1, 101, 5000, 3600);
    }
}
