SingleTokenVesting

Vesting Contract Address  -  0x3192C8FED0fafd012c083C3AA54C634a8DCb3fbd

Overview

The SingleTokenVesting smart contract allows users to create and manage vesting schedules for a globally set ERC20 token. Users can deposit tokens and claim them gradually over time based on predefined vesting durations.

Features

Global ERC20 Token: The contract supports a single token for all vesting schedules.

Fixed Vesting Durations: Users can choose from predefined vesting periods (90 days or 180 days).

Gradual Token Unlocking: Tokens are unlocked over time, allowing periodic claims.

Batch Vesting Creation: The owner can create multiple vesting schedules for different users in a single transaction.

Secure & Optimized: Implements OpenZeppelin's security mechanisms including ReentrancyGuard and Ownable.

Contract Details

State Variables

IERC20 public token - The ERC20 token used for vesting.

uint256[] public durations - Predefined vesting durations (90 days, 180 days).

uint256 public constant PERIOD = 30 days - The claim period interval.

mapping(address => VestingSchedule[]) public vestingSchedules - Stores vesting schedules per user.

Structs

VestingSchedule

uint256 totalAllocation - Total tokens allocated for vesting.

uint256 claimedAmount - Amount already claimed by the user.

uint256 duration - Duration of the vesting schedule.

uint256 startTime - Timestamp when vesting started.

bool active - Status of the vesting schedule.

Functions

setToken(IERC20 _token) external onlyOwner

Sets the ERC20 token used for vesting. Can only be called by the contract owner.

createVesting(uint256 amount, uint256 durationIndex) external nonReentrant

Allows a user to create a vesting schedule by specifying an amount and duration index (0 for 90 days, 1 for 180 days).

claim(uint256 index) external nonReentrant

Allows a user to claim vested tokens from a specific vesting schedule.

The function calculates the claimable amount and transfers tokens accordingly.

If the total allocated amount is fully claimed, the schedule is marked as inactive.

vestedAmount(address _user, uint256 index) public view returns (uint256)

Calculates the amount of tokens a user has vested based on time elapsed.

claimableAmount(address _user, uint256 index) external view returns (uint256)

Returns the amount of tokens a user can currently claim.

batchCreateVesting(address[] calldata users, uint256[] calldata amounts, uint256[] calldata durationIndexes) external onlyOwner nonReentrant
  - user can approve token to contract address after admin can transfer token from user to stake contract


Allows the contract owner to create vesting schedules for multiple users at once.

Ensures that users cannot have multiple vesting schedules with different durations.

Transfers the specified token amounts from the owner to the contract.

Events

TokenSet(address indexed token) - Emitted when the global token is set.

VestingCreated(address indexed user, uint256 amount, uint256 startTime) - Emitted when a new vesting schedule is created.

TokensClaimed(address indexed user, uint256 amount) - Emitted when a user claims tokens.

VestingBatchCreated(address[] users, uint256[] amounts) - Emitted when a batch of vesting schedules is created.

Security Considerations

Reentrancy Protection: The contract implements ReentrancyGuard to prevent reentrancy attacks.

Only Owner Restrictions: Functions like setToken and batchCreateVesting are restricted to the owner.

Validations: The contract checks for invalid durations, zero amounts, and correct ERC20 transfers.


