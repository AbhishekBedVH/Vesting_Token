// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SingleTokenVesting
 * @notice A contract for users to create and manage vesting schedules for a globally set ERC20 token.
 */
contract SingleTokenVesting is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        uint256 totalAllocation; // Total tokens allocated for vesting
        uint256 claimedAmount;   // Amount already claimed
        uint256 duration;        // Duration of the vesting period
        uint256 startTime;       // Vesting start timestamp
        bool active;             // Indicates if the vesting is active
    }

    IERC20 public token; // Global ERC20 token used for vesting
    uint256[] public durations = [90 days, 180 days]; // Supported vesting durations
    uint256 public constant PERIOD = 30 days; // Claim period interval

    mapping(address => VestingSchedule[]) public vestingSchedules; // User vesting schedules

    event TokenSet(address indexed token);
    event VestingCreated(address indexed user, uint256 amount, uint256 startTime);
    event TokensClaimed(address indexed user, uint256 amount);
    event VestingBatchCreated(address[] users, uint256[] amounts);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Sets the ERC20 token for vesting.
     * @param _token Address of the ERC20 token.
     */
    function setToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Token cannot be zero address");
        token = _token;
        emit TokenSet(address(_token));
    }

    /**
     * @notice Creates a new vesting schedule for the caller.
     * @param _amount Amount of tokens to vest.
     * @param _durationIndex Index of the vesting duration (0 or 1).
     */
    function createVesting(uint256 _amount, uint256 _durationIndex) external nonReentrant {
        require(address(token) != address(0), "Token not set");
        require(_amount > 0, "Amount must be positive");
        require(_durationIndex < durations.length, "Invalid duration");

        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];

        if(schedules.length == 0){
        require(
            schedules[0].duration == durations[_durationIndex],
            "Cannot stake in multiple durations"
        );
        }

        schedules.push(VestingSchedule(_amount, 0, durations[_durationIndex], block.timestamp, true));
        emit VestingCreated(msg.sender, _amount, block.timestamp);

        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Allows users to claim vested tokens.
     * @param index Index of the vesting schedule to claim from.
     */
    function claim(uint256 index) external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender][index];
        require(schedule.active, "No active vesting schedule");

        uint256 claimable = vestedAmount(msg.sender, index) - schedule.claimedAmount;
        require(claimable > 0, "Nothing to claim");

        schedule.claimedAmount += claimable;
        if (schedule.claimedAmount == schedule.totalAllocation) {
            schedule.active = false; // Mark vesting as inactive once fully claimed
        }
        token.safeTransfer(msg.sender, claimable);
        emit TokensClaimed(msg.sender, claimable);
    }

    /**
     * @notice Calculates the total vested amount for a user.
     * @param _user Address of the user.
     * @param index Index of the vesting schedule.
     * @return The amount of tokens that have vested.
     */
    function vestedAmount(address _user, uint256 index) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_user][index];
        if (!schedule.active) return 0;

        uint256 periodsPassed = (block.timestamp - schedule.startTime) / PERIOD;
        uint256 totalPeriods = schedule.duration / PERIOD;

        return (periodsPassed >= totalPeriods) ? schedule.totalAllocation : (schedule.totalAllocation * periodsPassed) / totalPeriods;
    }

    /**
     * @notice Returns the claimable amount for a user.
     * @param _user Address of the user.
     * @param index Index of the vesting schedule.
     * @return The amount of tokens the user can currently claim.
     */
    function claimableAmount(address _user, uint256 index) external view returns (uint256) {
        return vestedAmount(_user, index) - vestingSchedules[_user][index].claimedAmount;
    }

    /**
     * @notice Creates vesting schedules for multiple users in a batch.
     * @param users Array of user addresses.
     * @param amounts Array of corresponding vesting amounts.
     * @param durationIndexes Array of corresponding duration indexes.
     */
    function batchCreateVesting(
        address[] calldata users,
        uint256[] calldata amounts,
        uint256[] calldata durationIndexes
    ) external onlyOwner nonReentrant {
        require(address(token) != address(0), "Token not set");
        require(users.length == amounts.length && users.length == durationIndexes.length, "Array length mismatch");

        for (uint256 i = 0; i < users.length; i++) {
            require(durationIndexes[i] < durations.length, "Invalid duration index");
            uint256 durationTime = durations[durationIndexes[i]];
            VestingSchedule[] storage schedule = vestingSchedules[users[i]];

            if (schedule.length > 0) {
                durationTime  = schedule[0].duration;
            }
            schedule.push(VestingSchedule(amounts[i], 0, durationTime, block.timestamp, true));
            token.safeTransferFrom(users[i], address(this), amounts[i]);
        }

        emit VestingBatchCreated(users, amounts);
    }
}

