const hre = require("hardhat");
const { ethers } = require("hardhat");
const fs = require("fs"); // Node.js file system module for reading files
const path = require("path");

function formatTokenAmount(amount, decimals = 18, precision = 4) {
  // Convert BigNumber to string and get the integer part
  const str = ethers.formatUnits(amount, decimals);

  // Split the string into integer and fractional parts
  const parts = str.split(".");

  // Combine integer part and the specified number of decimal places
  const formatted = parts[0] + "." + (parts[1] || "").slice(0, precision);

  return parseFloat(formatted).toFixed(precision);
}

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

  // Deploy Services
  console.log();
  console.log("------------------------------------");
  console.log("| Deploying Services...");
  const ServicesContract = await hre.ethers.deployContract("Services", [], {});
  await ServicesContract.waitForDeployment();
  const ServicesContractAddress = ServicesContract.target;
  console.log(
    "| Services was successfully deployed at:",
    ServicesContractAddress
  );

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
  const servicesPath = path.resolve(
    __dirname,
    "../artifacts/contracts/Services.sol/Services.json"
  );

  // Getting the ABI's using the Paths
  const ERC20ABI = JSON.parse(fs.readFileSync(ERC20Path)).abi;
  const OracleABI = JSON.parse(fs.readFileSync(oraclePath)).abi;
  const ServicesABI = JSON.parse(fs.readFileSync(servicesPath)).abi;

  // 1. Create contract instances: ERC20
  const ERC20ContractInstance = new ethers.Contract(
    ERC20ContractAddress,
    ERC20ABI,
    deployer
  );

  // 2. Create contract instances: Oracle
  const OracleContractInstance = new ethers.Contract(
    OracleContractAddress,
    OracleABI,
    deployer
  );

  // 3. Create contract instances: Services
  const ServicesContractInstance = new ethers.Contract(
    ServicesContractAddress,
    ServicesABI,
    deployer
  );

  // Now we can deploy RewardingTool
  console.log();
  console.log("------------------------------------");
  console.log("| Deploying RewardingTool...");
  //   const RewardingToolFactory = await ethers.getContractFactory("RewardingTool");
  const RewardingToolContract = await hre.ethers.deployContract(
    "RewardingTool",
    [ERC20ContractInstance, OracleContractInstance, ServicesContractInstance],
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
  ERC20ContractInstance.loadUpContract(RewardingToolAddress);

  console.log();
  console.log("====== All Operations Completed Successfully! ======");
  console.log();
  console.log();
  console.log("====== Commencing Testing ======");
  console.log();

  const oldBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log(
    "| Account's Old MGS Balance: ",
    formatTokenAmount(oldBalance),
    " MGS"
  );

  //   const amountToApprove = hre.ethers.parseEther("1000"); // Change this to the amount you want
  console.log();
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);
  const RewardingContractWithSigner = RewardingToolContract.connect(deployer);
  await RewardingContractWithSigner.createUser("Souvlaki_Destroyer");

  const user = await RewardingContractWithSigner.users(deployer);

  console.log("User: ", user);

  await RewardingToolContractInstance.addPoints("forum", "submitComment");
  await RewardingToolContractInstance.addPoints("forum", "voteOnComment");
  await RewardingToolContractInstance.addPoints("forum", "voteOnPost");

  const newBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log(
    "| Account's New MGS Balance: ",
    formatTokenAmount(newBalance),
    " MGS"
  );

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
