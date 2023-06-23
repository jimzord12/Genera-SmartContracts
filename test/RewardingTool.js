const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { main } = require("../scripts/deployContracts");

describe("RewardingTool - Test", function () {
  //   async function initialSetup() {
  //     const {
  //       ERC20ContractInstance,
  //       OracleContractInstance,
  //       RewardingToolContractInstance,
  //       deployer,
  //     } = await main();

  //     return {
  //       ERC20ContractInstance,
  //       OracleContractInstance,
  //       RewardingToolContractInstance,
  //       deployer,
  //     };
  //   }

  let ERC20ContractInstance;
  let OracleContractInstance;
  let RewardingToolContractInstance;
  let deployer;

  beforeEach(async function () {
    const deploymentResult = await main();
    ERC20ContractInstance = deploymentResult.ERC20ContractInstance;
    OracleContractInstance = deploymentResult.OracleContractInstance;
    RewardingToolContractInstance =
      deploymentResult.RewardingToolContractInstance;
    deployer = deploymentResult.deployer;
  });

  //   it("Should reward the caller with 100 tokens", async function () {
  //     const {
  //       ERC20ContractInstance,
  //       OracleContractInstance,
  //       RewardingToolContractInstance,
  //       deployer,
  //     } = await loadFixture(initialSetup);
  //     // const initialBalance = await erc20.balanceOf(dev.address);
  //     const old_balance = await ERC20ContractInstance.balanceOf(deployer);
  //     console.log("AA:::", old_balance);
  //     // console.log("Deployer's Old Balance: " + old_balance);

  //     // Add points
  //     await RewardingToolContractInstance.connect(deployer).addPoints(
  //       "forum",
  //       "submitComment"
  //     );

  //     // Make sure the rewardingTool contract has enough tokens to give out
  //     expect(
  //       (await ERC20ContractInstance.balanceOf(deployer)).to.equal(
  //         old_balance.add(ethers.utils.parseUnits("100", "wei"))
  //       )
  //     ).to.be.true;
  //   });
});
