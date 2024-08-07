// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IClubPool {
    event Joined(address indexed member, uint256 amount);
    event Slashed(address indexed runner);
    event Vetoed(address indexed runner);
    event Claimed(address indexed member, uint256 amount);
    event ActivityRecorded(uint256 userId, uint256 activityId, uint256 distance, uint256 time);

    function join(uint256 userId) external payable;
    function startClub() external;
    function vetoSlash(address _runner) external;
    function claim() external;
    function totalStakes() external view returns (uint256);
    function isSlashed(address _runner) external view returns (bool);
    function stakes(address _member) external view returns (uint256);
    // function slashVotes(address _runner) external view returns (uint256);
    function recordRun(uint256 userId, uint256 activityId, uint256 distance, uint256 time) external;
    function setEndTime(uint256 _endTime) external;
}
