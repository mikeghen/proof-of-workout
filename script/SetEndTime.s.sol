// script/DeployTestnet.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ClubPool.sol";
import "../src/Mocks/MockUSDC.sol";

contract DeployTestnet is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 endTime = block.timestamp + 1 minutes; // Set for the need
        address clubPool = 0xb7cCfb9F66eaE7AC946F713987D47cE468476806;

        // Owner deploys the club pool
        vm.startBroadcast(ownerKey);
        IClubPool cp = IClubPool(clubPool);
        cp.setEndTime(endTime);
        vm.stopBroadcast();

    }
}