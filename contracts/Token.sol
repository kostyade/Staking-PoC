// /$$$$$$$$ /$$   /$$ /$$   /$$
//|__  $$__/| $$  /$$/| $$$ | $$
//   | $$   | $$ /$$/ | $$$$| $$
//   | $$   | $$$$$/  | $$ $$ $$
//   | $$   | $$  $$  | $$  $$$$
//   | $$   | $$\  $$ | $$\  $$$
//   | $$   | $$ \  $$| $$ \  $$
//   |__/   |__/  \__/|__/  \__/
//
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TKN is ERC20("Token", "TKN"), Ownable {
    address private stakingAddress;

    function setStakingAddress(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
    }

    //It would be nice to add separate role via AccessControl though I'm lazy to do it for test scenario
    function mintRewards(uint256 amount) public onlyOwner {
        require(stakingAddress != address(0x0), "Staking address must be set");
        _mint(stakingAddress, amount);
    }

    //ownership must be transferred to zero address to avoid rug from owner, but this will require more roles
    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
}
