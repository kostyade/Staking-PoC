const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function () {
  // eslint-disable-next-line no-unused-vars
  let owner, degen1, degen2;
  let token, staking;

  beforeEach(async function () {
    [owner, degen1, degen2] = await ethers.getSigners();

    // Deploying ERC20 contract
    const TKN = await ethers.getContractFactory("TKN");
    token = await TKN.deploy();
    await token.deployed();

    // Deploying Staking contract
    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(token.address);
    await staking.deployed();

    // Set staking address, pre-mint and distribute initial supply
    await token.setStakingAddress(staking.address);
    await token.mint(1000000);
    await token.transfer(degen1.address, 1000);
    await token.transfer(degen2.address, 2000);

    // Set allowance
    await token
      .connect(degen1)
      .approve(staking.address, await token.balanceOf(degen1.address));

    await token
      .connect(degen2)
      .approve(staking.address, await token.balanceOf(degen2.address));
  });

  describe("Staking scenarios", function () {
    it("Should update balances after staking", async function () {
      await staking.connect(degen1).stake(100);
      await staking.connect(degen2).stake(200);

      expect(await staking.balanceOf(degen1.address)).to.be.equal(100);
      expect(await staking.balanceOf(degen2.address)).to.be.equal(200);
    });
    it("Degens should get rewards properly distributed", async function () {
      await staking.connect(degen1).stake(100);
      await staking.connect(degen2).stake(200);

      await token.mintRewards(9000);
      await staking.distribute(9000);

      expect(await staking.balanceOf(degen1.address)).to.be.equal(3100);
      expect(await staking.balanceOf(degen2.address)).to.be.equal(6200);
    });
    it("Degens should be able to get money back :D", async function () {
      await staking.connect(degen1).stake(100);
      await staking.connect(degen2).stake(200);

      await token.mintRewards(9000);
      await staking.distribute(9000);

      await staking.connect(degen1).withdraw();
      await staking.connect(degen2).withdraw();

      expect(await token.balanceOf(degen1.address)).to.be.equal(4000);
      expect(await token.balanceOf(degen2.address)).to.be.equal(8000);
    });
  });
});
