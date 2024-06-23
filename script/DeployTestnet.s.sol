// deployClubPoolFactory.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ClubPoolFactory.sol";
import "../src/mocks/MockUSDC.sol";

// Usage:
// 
// forge script script/DeployTestnet.s.sol --broadcast --rpc-url http://127.0.0.1:8545 --revert-on-error

contract DeployTestnet is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 runnerKey = vm.envUint("RUNNER_PRIVATE_KEY");
        address runner = address(uint160(uint256(keccak256(abi.encodePacked(runnerKey)))));

        // Owner deloys the club pool
        vm.startBroadcast(ownerKey);
        MockUSDC usdc = new MockUSDC();
        ClubPool clubPool = new ClubPool(address(usdc), 12 weeks, address(this), 50 * 1e6);
        usdc.mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100 * 1e6);
        vm.stopBroadcast();

        // Runner registers to the club pool
        vm.startBroadcast(runnerKey);
        usdc.approve(address(clubPool), 50 * 1e6);
        clubPool.join();
        vm.stopBroadcast();
    }
}
