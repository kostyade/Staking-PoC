//  /$$$$$$  /$$$$$$$$ /$$$$$$  /$$   /$$ /$$$$$$ /$$   /$$  /$$$$$$
// /$$__  $$|__  $$__//$$__  $$| $$  /$$/|_  $$_/| $$$ | $$ /$$__  $$
//| $$  \__/   | $$  | $$  \ $$| $$ /$$/   | $$  | $$$$| $$| $$  \__/
//|  $$$$$$    | $$  | $$$$$$$$| $$$$$/    | $$  | $$ $$ $$| $$ /$$$$
// \____  $$   | $$  | $$__  $$| $$  $$    | $$  | $$  $$$$| $$|_  $$
// /$$  \ $$   | $$  | $$  | $$| $$\  $$   | $$  | $$\  $$$| $$  \ $$
//|  $$$$$$/   | $$  | $$  | $$| $$ \  $$ /$$$$$$| $$ \  $$|  $$$$$$/
// \______/    |__/  |__/  |__/|__/  \__/|______/|__/  \__/ \______/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

// Single token staking contract without auto compounding
// It requires more stuff like events, more view functions, but should work in general :)

contract Staking is ReentrancyGuard, Ownable, Pausable {
    IERC20 private stakingToken;

    uint256 private totalStaked;
    uint256 private currentRewardPerToken;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private rewardAtDeposit;
    mapping(address => uint256) private earnings;

    /*╔═════════════════════════════════╗
      ║            MODIFIERS            ║
      ╚═════════════════════════════════╝*/

    modifier updateEarnings(address _account) {
        earnings[_account] +=
            ((currentRewardPerToken - rewardAtDeposit[_account]) *
                balances[_account]) /
            1e18;
        _;
    }

    /*╔═════════════════════════════════╗
      ║            CONSTRUCTOR          ║
      ╚═════════════════════════════════╝*/

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    /*╔═════════════════════════════════╗
      ║            VIEWS                ║
      ╚═════════════════════════════════╝*/

    function totalSupply() external view returns (uint256) {
        return totalStaked;
    }

    function stakedBalanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function balanceOf(address _account) external view returns (uint256) {
        return
            balances[_account] +
            earnings[_account] +
            ((currentRewardPerToken - rewardAtDeposit[_account]) *
                balances[_account]) /
            1e18;
    }

    function earningsOf(address _account) external view returns (uint256) {
        return
            earnings[_account] +
            ((currentRewardPerToken - rewardAtDeposit[_account]) *
                balances[_account]) /
            1e18;
    }

    /*╔═════════════════════════════════╗
      ║            EXTERNAL             ║
      ╚═════════════════════════════════╝*/

    function stake(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        updateEarnings(msg.sender)
    {
        balances[msg.sender] += _amount;
        rewardAtDeposit[msg.sender] = currentRewardPerToken;
        totalStaked += _amount;

        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function claimAndStakeAll()
        external
        nonReentrant
        whenNotPaused
        updateEarnings(msg.sender)
    {
        uint256 _amount = earnings[msg.sender];
        balances[msg.sender] += _amount;
        rewardAtDeposit[msg.sender] = currentRewardPerToken;
        totalStaked += _amount;
        earnings[msg.sender] = 0;
    }

    function withdraw()
        external
        nonReentrant
        whenNotPaused
        updateEarnings(msg.sender)
    {
        uint256 amountToWithdraw = balances[msg.sender] + earnings[msg.sender];
        totalStaked -= balances[msg.sender];
        balances[msg.sender] = 0;
        earnings[msg.sender] = 0;

        stakingToken.transfer(msg.sender, amountToWithdraw);
    }

    function distribute(uint256 _reward) external whenNotPaused onlyOwner {
        require(totalStaked != 0, "There are no stakers");
        require(
            stakingToken.balanceOf(address(this)) >= _reward,
            "Not enough funds to distribute"
        );
        currentRewardPerToken += (_reward * 1e18) / totalStaked;
    }
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
