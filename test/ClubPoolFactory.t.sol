// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ClubPoolFactory} from "../src/ClubPoolFactory.sol";
import {ClubPool} from "../src/ClubPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClubPoolFactoryTest is Test {
    ClubPoolFactory public factory;
    IERC20 public usdc;
    address public owner = address(0x123);
    address public nonOwner = address(0x456);
    uint public clubId = 1;

    function setUp() public {
        vm.prank(owner);
        factory = new ClubPoolFactory();
        usdc = IERC20(address(new MockERC20()));
    }

    function testCreateClubPool() public {
        uint256 duration = 30 days;
        uint256 requiredDistance = 1000;
        uint256 stakeAmount = 1000 * 10 ** 18;

        vm.prank(owner);
        factory.createClubPool(clubId, address(usdc), duration, requiredDistance, stakeAmount);

        address[] memory deployedPools = factory.getDeployedPools();
        assertEq(deployedPools.length, 1);

        ClubPool newPool = ClubPool(deployedPools[0]);

        assertEq(address(newPool.usdc()), address(usdc));
        assertEq(newPool.duration(), duration);
        assertEq(newPool.requiredDistance(), requiredDistance);
        assertEq(newPool.individualStake(), stakeAmount);

    }

    function testOnlyOwnerCanCreateClubPool() public {
        vm.startPrank(nonOwner);

        uint256 duration = 30 days;
        uint256 requiredDistance = 1000;
        uint256 stakeAmount = 1000 * 10 ** 18;
        vm.expectRevert("Not the Owner");
        factory.createClubPool(clubId, address(usdc), duration, requiredDistance, stakeAmount);

        vm.stopPrank();
    }
}

contract MockERC20 is IERC20 {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private _totalSupply;

    function name() public pure returns (string memory) {
        return "MockERC20";
    }

    function symbol() public pure returns (string memory) {
        return "MERC20";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) external {
        balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }
}
