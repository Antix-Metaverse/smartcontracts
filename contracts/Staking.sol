// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    IERC20 public immutable stakingToken;
    IERC721 public immutable accessNFT;

    uint256 public constant NUM_TIERS = 6;
    uint256 public constant EPOCH_DURATION = 7 days;

    // Tier: [5%, 8%, 12%, 20%, 25%, 30%]
    uint256[NUM_TIERS] public tierPercentsBP = [
        500,
        800,
        1200,
        2000,
        2500,
        3000
    ];

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTimestamp;
        uint8 currentTier;
    }

    uint256 public immutable genesis;
    uint256 public weeklyRewardPool;
    uint256 public rewardBalance;

    // totalTierStake[epoch][tier]
    mapping(uint256 => uint256[NUM_TIERS]) public totalTierStakeAtEpochStart;
    uint256[NUM_TIERS] public currentTierStakes;

    mapping(address => StakeInfo) public stakes;
    mapping(address => mapping(uint256 => bool)) public claimed; // user => epoch => claimed

    event Snapshot(uint256 epoch);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 epoch, uint256 reward);
    event RewardsDeposited(address indexed from, uint256 amount);
    event RewardsWithdrawed(address indexed to, uint256 amount);
    event WeeklyRewardPoolChanged(uint256 amount);

    constructor(
        address _stakingToken,
        address _accessNFT,
        uint256 _weeklyRewardPool
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        accessNFT = IERC721(_accessNFT);
        weeklyRewardPool = _weeklyRewardPool;
        genesis = block.timestamp;
    }

    modifier onlyWithNFT() {
        require(accessNFT.balanceOf(msg.sender) > 0, "NFT required to stake");
        _;
    }

    function depositRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount is zero");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance += amount;
        emit RewardsDeposited(msg.sender, amount);
    }

    function withdrawRewards(uint256 amount) external onlyOwner {
        require(rewardBalance >= amount, "Wrong amount");
        rewardBalance -= amount;
        stakingToken.transfer(msg.sender, amount);
        emit RewardsWithdrawed(msg.sender, amount);
    }

    function setWeeklyRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero reward pool");
        weeklyRewardPool = amount;
        emit WeeklyRewardPoolChanged(amount);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - genesis) / EPOCH_DURATION;
    }

    function getEpochStart(uint256 epoch) public view returns (uint256) {
        return genesis + epoch * EPOCH_DURATION;
    }

    function getTier(uint256 amount) public pure returns (uint8) {
        if (amount >= 250000 ether) return 5;
        if (amount >= 130000 ether) return 4;
        if (amount >= 60000 ether) return 3;
        if (amount >= 30000 ether) return 2;
        if (amount >= 15000 ether) return 1;
        if (amount >= 7500 ether) return 0;
        revert("Not enough for Tier 1");
    }

    function lockMultiplierForLockYears(
        uint256 time
    ) public pure returns (uint256) {
        if (time == 3) return 15000; // 1.50x
        if (time == 2) return 12500; // 1.25x
        if (time == 1) return 11000; // 1.10x
        revert("Invalid lock period");
    }

    function _snapshotTierStakesIfNeeded(uint256 epoch) internal {
        if (
            totalTierStakeAtEpochStart[epoch][0] == 0 &&
            getEpochStart(epoch) < block.timestamp
        ) {
            for (uint8 i = 0; i < NUM_TIERS; i++) {
                totalTierStakeAtEpochStart[epoch][i] = currentTierStakes[i];
            }
        }
        emit Snapshot(epoch);
    }

    function manualSnapshot(uint256 epoch) external onlyOwner {
        _snapshotTierStakesIfNeeded(epoch);
    }

    function stake(uint256 amount) external onlyWithNFT nonReentrant {
        require(amount > 0, "Amount must be > 0");

        StakeInfo storage info = stakes[msg.sender];
        stakingToken.transferFrom(msg.sender, address(this), amount);

        require(info.amount == 0, "Already staked");
        info.amount = amount;

        uint8 newTier = getTier(info.amount);

        info.stakeTimestamp = block.timestamp;
        info.currentTier = newTier;
        currentTierStakes[newTier] += info.amount;
        emit Staked(msg.sender, amount);
    }

    function unstake() external nonReentrant {
        StakeInfo storage info = stakes[msg.sender];
        uint256 amount = info.amount;
        require(amount > 0, "No stake");
        currentTierStakes[info.currentTier] -= amount;

        delete stakes[msg.sender];
        stakingToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function getUserStakeAndTotalTierAtEpoch(
        address user,
        uint256 epoch
    ) public view returns (uint256, uint8, uint256) {
        StakeInfo storage info = stakes[user];
        uint256 epochStart = getEpochStart(epoch);
        if (info.amount == 0 || info.stakeTimestamp >= epochStart) {
            return (0, 0, 0);
        }
        uint8 userTier = getTier(info.amount);
        uint256 totalTier = totalTierStakeAtEpochStart[epoch][userTier];
        return (info.amount, userTier, totalTier);
    }

    function claimReward(uint256 epoch) external nonReentrant {
        require(epoch < getCurrentEpoch(), "Epoch not finished");
        require(!claimed[msg.sender][epoch], "Already claimed");

        _snapshotTierStakesIfNeeded(epoch);

        (
            uint256 userStake,
            uint8 userTier,
            uint256 totalTierStake
        ) = getUserStakeAndTotalTierAtEpoch(msg.sender, epoch);

        require(
            userStake > 0 && totalTierStake > 0,
            "No eligible stake for epoch"
        );

        StakeInfo storage info = stakes[msg.sender];
        uint256 lockMultiplierBP = lockMultiplierForLockYears(
            block.timestamp - info.stakeTimestamp
        );

        uint256 tierRewardPool = (weeklyRewardPool * tierPercentsBP[userTier]) /
            10000;
        uint256 reward = (tierRewardPool * userStake * lockMultiplierBP) /
            (totalTierStake * 10000);

        require(reward <= rewardBalance, "Not enough rewards");
        rewardBalance -= reward;

        claimed[msg.sender][epoch] = true;
        stakingToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, epoch, reward);
    }
}
