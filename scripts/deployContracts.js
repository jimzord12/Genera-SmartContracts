const hre = require("hardhat");
const { ethers } = require("hardhat");
const fs = require("fs"); // Node.js file system module for reading files
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log();
  console.log("====== Commencing Contract Deployment ======");

  // Deploy ERC-20
  console.log();
  console.log("------------------------------------");
  console.log("| Deploying ERC-20...");
  const ERC20Contract = await hre.ethers.deployContract("MyGreenScore", [], {});
  await ERC20Contract.waitForDeployment();
  const ERC20ContractAddress = ERC20Contract.target;
  console.log("| ERC-20 was successfully deployed at:", ERC20ContractAddress);

  // Deploy Oracle
  console.log();
  console.log("------------------------------------");
  console.log("| Deploying Oracle...");
  const OracleContract = await hre.ethers.deployContract("Oracle", [], {});
  await OracleContract.waitForDeployment();
  const OracleContractAddress = OracleContract.target;
  console.log("| Oracle was successfully deployed at:", OracleContractAddress);

  // Using Node's filesystem to get the 2 ABI's
  // Assuming the ABI's are stored in the 'build/contracts' folder with names 'YourERC20ContractName.json' and 'YourOracleContractName.json'
  // Getting the Paths
  const ERC20Path = path.resolve(
    __dirname,
    "../artifacts/contracts/MyGreenScore.sol/MyGreenScore.json"
  );
  const oraclePath = path.resolve(
    __dirname,
    "../artifacts/contracts/Oracle.sol/Oracle.json"
  );

  // Getting the ABI's using the Paths
  const ERC20ABI = JSON.parse(fs.readFileSync(ERC20Path)).abi;
  const OracleABI = JSON.parse(fs.readFileSync(oraclePath)).abi;

  // Create contract instances
  const ERC20ContractInstance = new ethers.Contract(
    ERC20ContractAddress,
    ERC20ABI,
    deployer
  );
  const OracleContractInstance = new ethers.Contract(
    OracleContractAddress,
    OracleABI,
    deployer
  );

  // Now we can deploy RewardingTool
  console.log();
  console.log("------------------------------------");
  console.log("| Deploying RewardingTool...");
  //   const RewardingToolFactory = await ethers.getContractFactory("RewardingTool");
  const RewardingToolContract = await hre.ethers.deployContract(
    "RewardingTool",
    [ERC20ContractInstance, OracleContractInstance],
    {}
  );
  await RewardingToolContract.waitForDeployment();
  const RewardingToolAddress = RewardingToolContract.target;

  const RewardingToolPath = path.resolve(
    __dirname,
    "../artifacts/contracts/RewardingTool.sol/RewardingTool.json"
  );

  const RewardingToolABI = JSON.parse(fs.readFileSync(RewardingToolPath)).abi;

  const RewardingToolContractInstance = new ethers.Contract(
    RewardingToolAddress,
    RewardingToolABI,
    deployer
  );

  console.log(
    "| RewardingTool was successfully deployed to:",
    RewardingToolAddress
  );
  ERC20ContractInstance.loadUpRewardingTool(RewardingToolAddress);

  console.log();
  console.log("====== All Operations Completed Successfully! ======");
  console.log();
  console.log();
  console.log("====== Commencing Testing ======");
  console.log();

  const oldBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log("| Account's Old MGS Balance: ", oldBalance);

  //   const amountToApprove = hre.ethers.parseEther("1000"); // Change this to the amount you want
  console.log("We got pass this #1");
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);

  await RewardingToolContractInstance.addPoints("forum", "submitComment");

  const newBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log("| Account's New MGS Balance: ", newBalance);

  return {
    ERC20ContractInstance,
    OracleContractInstance,
    RewardingToolContractInstance,
    deployer,
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

module.exports = {
  main,
};
