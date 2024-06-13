// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IClubPool {
    event Joined(address indexed member, uint256 amount);
    event Slashed(address indexed runner);
    event Vetoed(address indexed runner);
    event Claimed(address indexed member, uint256 amount);

    function join() external payable;
    function startClub() external;
    function proposeSlash(address _runner) external;
    function vetoSlash(address _runner) external;
    function claim() external;
    function totalStakes() external view returns (uint256);
    function isSlashed(address _runner) external view returns (bool);
    function stakes(address _member) external view returns (uint256);
    function slashVotes(address _runner) external view returns (uint256);
}