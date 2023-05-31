// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingToken is ERC20, Ownable {
    using SafeMath for uint256;

    // Staking details for each user
    struct StakingInfo {
        uint256 stakedAmount;
        uint256 stakedTime;
    }

    mapping(address => StakingInfo) public stakingInfo;

    // Staking rewards parameters
    uint256 public rewardRate; // Rewards rate in percentage (e.g., 5 for 5%)
    uint256 public rewardInterval; // Rewards interval in seconds

    // ERC20 token details
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply,
        uint256 initialRewardRate,
        uint256 initialRewardInterval
    ) ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        rewardRate = initialRewardRate;
        rewardInterval = initialRewardInterval;
        _mint(msg.sender, initialSupply);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingInfo[msg.sender].stakedAmount == 0, "Already staked");

        // Transfer tokens from user to contract
        _transfer(msg.sender, address(this), amount);

        // Update staking details
        stakingInfo[msg.sender].stakedAmount = amount;
        stakingInfo[msg.sender].stakedTime = block.timestamp;
    }

    function unstake() external {
        require(stakingInfo[msg.sender].stakedAmount > 0, "No staked amount");

        // Calculate reward amount
        uint256 rewardAmount = calculateReward(msg.sender);

        // Transfer staked tokens + rewards back to the user
        _transfer(address(this), msg.sender, stakingInfo[msg.sender].stakedAmount.add(rewardAmount));

        // Reset staking details
        delete stakingInfo[msg.sender];
    }

    function calculateReward(address account) public view returns (uint256) {
        require(stakingInfo[account].stakedAmount > 0, "No staked amount");

        uint256 stakedTime = stakingInfo[account].stakedTime;
        uint256 stakedDuration = block.timestamp.sub(stakedTime);

        uint256 rewardAmount = stakingInfo[account].stakedAmount.mul(rewardRate).div(100);
        rewardAmount = rewardAmount.mul(stakedDuration).div(rewardInterval);

        return rewardAmount;
    }

    function updateRewardRate(uint256 newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
    }

    function updateRewardInterval(uint256 newRewardInterval) external onlyOwner {
        rewardInterval = newRewardInterval;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}