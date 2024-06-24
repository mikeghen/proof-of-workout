// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IClubPool} from "./interfaces/IClubPool.sol";
import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title IClubPool Interface
/// @notice Interface for the ClubPool contract

contract ClubPool is IClubPool, ERC721Enumerable {
    IERC20 public usdc;
    uint256 public duration;
    uint256 public endTime;
    uint256 public requiredMiles;
    uint256 individualStake;
    uint256 public totalStake;
    bool public started;
    address owner;

    struct Member {
        uint256 stake;
        bool slashed;
        bool claimed;
        uint256 slashVotes;
    }

    struct RunData {
        uint256 miles;
        uint256 timestamp;
    }

    uint256 private _nextTokenId;

    mapping(address => Member) public members;
    mapping(uint256 => RunData) private _runData;
    address[] public memberList;

    event RunRecorded(address indexed runner, uint256 indexed tokenId, uint256 miles, uint256 timestamp);

    

    modifier onlyStarted() {
        require(started, "Club has not started yet");
        _;
    }

    modifier onlyNotStarted() {
        require(!started, "Club has already started");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    constructor(
        address _usdc,
        uint256 _duration,
        uint256 _requiredMiles,
        address _owner,
        uint256 _stakeAmount
    ) ERC721("RunNFT", "RUNNFT") {
        usdc = IERC20(_usdc);
        duration = _duration;
        owner = _owner;
        requiredMiles = _requiredMiles;
        individualStake = _stakeAmount;
        owner = _owner;
    }


    /**
     * @notice Allows a user to join the club by staking a specific amount of USDC.
     * @dev Transfers the specified amount of USDC from the caller to the contract.
     */
    function join() external payable override onlyNotStarted {
        require(members[msg.sender].stake == 0, "Already a member");
        require(usdc.transferFrom(msg.sender, address(this), individualStake), "USDC transfer failed");

        members[msg.sender] = Member({
            stake: individualStake,
            slashed: false,
            claimed: false,
            slashVotes: 0
        });
        memberList.push(msg.sender);
        totalStake += individualStake;

        emit Joined(msg.sender, individualStake);
    }

    function startClub() external override onlyNotStarted onlyOwner {
        started = true;
        endTime = block.timestamp + duration;
    }

    function recordRun(address runner, uint256 miles) external onlyStarted {
        require(members[runner].stake > 0, "Not a member");

        uint256 tokenId = _nextTokenId++;
        _mint(runner, tokenId);

        _runData[tokenId] = RunData({
            miles: miles,
            timestamp: block.timestamp
        });

        emit RunRecorded(runner, tokenId, miles, block.timestamp);
    }

    function getRunData(uint256 tokenId) external view returns (uint256 miles, uint256 timestamp) {
        RunData memory run = _runData[tokenId];
        return (run.miles, run.timestamp);
    }
    
    function proposeSlash(address _runner) external override onlyStarted {
        require(members[msg.sender].stake > 0, "Not a member");
        require(!members[_runner].slashed, "Runner already slashed");

        members[_runner].slashVotes += 1;

        if (members[_runner].slashVotes >= 2) {
            members[_runner].slashed = true;
            totalStake -= members[_runner].stake;

            uint256 share = members[_runner].stake / (memberList.length - 1);
            for (uint256 i = 0; i < memberList.length; i++) {
                if (memberList[i] != _runner) {
                    members[memberList[i]].stake += share;
                }
            }

            emit Slashed(_runner);
        }
    }

    function vetoSlash(address _runner) external override onlyStarted onlyOwner {
        require(members[_runner].slashed = true, "Runner not slashed");

        members[_runner].slashed = false;
        members[_runner].slashVotes = 0;

        emit Vetoed(_runner);
    }

    function claim() external override onlyStarted {
        require(block.timestamp >= endTime, "Club duration not ended");
        require(members[msg.sender].stake > 0, "Not a member");
        
        if (members[msg.sender].slashed == true) {
            revert("You have been slashed");
        }
        
        if (members[msg.sender].claimed == true) {
            revert("Already Claimed");
        }

        uint256 amount = members[msg.sender].stake;
        members[msg.sender].stake = 0;
        members[msg.sender].claimed = true;

        require(usdc.transfer(msg.sender, amount), "USDC transfer failed");

        emit Claimed(msg.sender, amount);
    }

    function totalStakes() external view override returns (uint256) {
        return totalStake;
    }

    function isSlashed(address _runner) external view override returns (bool) {
        return members[_runner].slashed;
    }

    function stakes(address _member) external view override returns (uint256) {
        return members[_member].stake;
    }

    function slashVotes(address _runner) external view override returns (uint256) {
        return members[_runner].slashVotes;
    }

    /**
     * @notice Records an activity for a member.
     * @param userId The ID of the user.
     * @param activityId The ID of the activity.
     * @param distance The distance covered in the activity.
     * @param time The time taken for the activity.
     */
    function recordActivity(uint256 userId, uint256 activityId, uint256 distance, uint256 time) external override {
        // Implementation for recording activity
        emit ActivityRecorded(userId, activityId, distance, time);
    }

    // rules on how a user can be Slashed 
    // a user can only be slashed if they don't reach there require miles for the week
    // If user has run the required miles they are save
    // else they can be slashed
    // Each run is save as an nft
    // After each run the nft the nft will have the miles the user ran
    // Miles will me in the meta data of the nft
    // The nft contract that will be used is an erc721 enumerable
    // use tokenOfOwnerByIndex() to check a group of an users nfts
    // example alice starts a group with Bob and eve
    // after every run alice, bob, and eve gets an nft with the miles run each of their individual runs
    // after each week the miles are total for that specic week
    // eve doesn't reach the mile total of the week so she can be slashed, while Alice and bob can not be slashed because they hit the required miles 
    // check blocktimes of NFT to make sure they are between the desired time
    // Change the duration to start and end time
    // we need a sub time check that checks the past 7 days at a speicific time which checks after the first run was recorded
    // this check should be done automaticly using gelato network but for testing manual is fine but allow for it to be easy to change if from manual to auto
    // factory creates the runnft and it allows users check user

    // No do this first update the start and end time
    // 1. Work on adding nft
    //  a. create runNft.sol import erc721 enumerable
    //  b. add a getmiles() function
    //  c. when mint is called miles run
    // 2. group leader calls ----> club factory creates ----> runNft & saverava contracts 
    // permission allow users to mint from groups after runs for factory to saverava // supports interface
    //  a. group leader is the admin caller
    // 3. add checking nft metadata
    // 4. update slashing
}
