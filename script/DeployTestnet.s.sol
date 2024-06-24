// script/DeployTestnet.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ClubPoolFactory.sol";
import "../src/Mocks/MockUSDC.sol";

contract DeployTestnet is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 runnerKey = vm.envUint("RUNNER_PRIVATE_KEY");

        // Owner deploys the club pool
        vm.startBroadcast(ownerKey);
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        ClubPool clubPool = new ClubPool(address(usdc), 12 weeks, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 50 * 1e6);
        console.log("ClubPool deployed at:", address(clubPool));

        usdc.mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100 * 1e6);
        vm.stopBroadcast();

        // Runner registers to the club pool
        vm.startBroadcast(runnerKey);
        usdc.approve(address(clubPool), 50 * 1e6);
        // clubPool.join();
        vm.stopBroadcast();

        vm.startBroadcast(ownerKey);
        clubPool.startClub();
        vm.stopBroadcast();

        // Log final state
        console.log("Runner joined the ClubPool with address:", address(clubPool));
    }
}
