// script/DeployTestnet.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ClubPool.sol";
import "../src/Mocks/MockUSDC.sol";

contract DeployTestnet is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 runnerKey = vm.envUint("RUNNER_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        address runnerAddress = vm.envAddress("RUNNER_ADDRESS");
        uint256 clubId = 1256143;

        // Owner deploys the club pool
        vm.startBroadcast(ownerKey);
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        ClubPool clubPool = new ClubPool(clubId, address(usdc), 30 days, 5, deployerAddress, 50 * 1e6);
        console.log("ClubPool deployed at:", address(clubPool));

        usdc.mint(runnerAddress, 100 * 1e6);
        console.log("Minted 100 USDC to runner:", runnerAddress);
        console.log("Runner USDC balance:", usdc.balanceOf(runnerAddress));
        vm.stopBroadcast();

        // Runner registers to the club pool
        vm.startBroadcast(runnerKey);
        usdc.approve(address(clubPool), 50 * 1e6);
        clubPool.join(1); // runner joins the club with userId 1
        console.log("Runner joined the club with userId 1");
        console.log("Runner USDC balance after joining:", usdc.balanceOf(runnerAddress));
        vm.stopBroadcast();

        // Start the club
        vm.startBroadcast(ownerKey);
        clubPool.startClub();
        vm.stopBroadcast();

        // Record a run for the runner
        vm.startBroadcast(runnerKey);
        uint256 activityId = 1;
        uint256 distance = 5; // The distance for the run
        uint256 time = 30 minutes; // The time for the run
        clubPool.recordRun(1, activityId, distance, time);
        console.log("Runner recorded a run with activityId 1, distance 5, and time 30 minutes");
        vm.stopBroadcast();

        // Fetch and log the runner's run data
        (uint256 recordedDistance, uint256 timestamp) = clubPool.getRunData(0);
        console.log("Runner's recorded distance:", recordedDistance);
        console.log("Runner's recorded timestamp:", timestamp);

        // Log final state
        console.log("Runner joined and recorded a run in the ClubPool with address:", address(clubPool));
    }
}
