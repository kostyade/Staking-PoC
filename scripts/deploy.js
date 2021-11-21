const hre = require("hardhat");

async function main() {
  const TKN = await hre.ethers.getContractFactory("TKN");
  const token = await TKN.deploy();

  await token.deployed();

  console.log("TKN contract deployed to:", token.address);

  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(token.address);

  await staking.deployed();

  console.log("Staking contract deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
