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
  // const networkName = "genera";
  // console.log("AAAAAAAAAA: ", hre.network.config);
  // const network = hre.network.config.networks[networkName];
  // const provider = new ethers.JsonRpcProvider(network.url, network.chainId);

  const [deployer, manager] = await ethers.getSigners();

  console.log();
  console.log("====== Commencing Contract Deployment ======");
  console.log();
  console.log("==> Running on network:", hre.network.name);
  console.log();
  console.log("==> The Deployer Address is: ", await deployer.getAddress());

  const deployerBalance = await ethers.provider.getBalance(deployer.address);

  console.log();
  console.log(
    "- How much ETH does the Deployer have? : ",
    ethers.formatEther(deployerBalance),
    "ETH"
  );
  console.log();
  console.log(
    "- Does the Deployer require Spending Money? : ",
    ethers.formatEther(deployerBalance) <= 5
  );
  console.log();

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

  // Part 1: Write the contracts' addresses to a JSON file
  const contractAddresses = {
    ERC20ContractAddress: ERC20ContractAddress,
    OracleContractAddress: OracleContractAddress,
    ServicesContractAddress: ServicesContractAddress,
    RewardingToolAddress: RewardingToolAddress,
  };

  // Part 2: Write the contracts' addresses to a JSON file
  fs.writeFileSync(
    path.resolve(__dirname, "../deployedContracts.json"),
    JSON.stringify(contractAddresses, null, 2)
  );

  console.log();
  console.log("-----------------------------------------------------------");
  console.log("✅ Contract addresses written to 'deployedContracts.json'.");
  console.log("-----------------------------------------------------------");
  console.log();

  console.log("-----------------------------------------------------------");
  console.log();
  console.log("====== Loading Up the Rewarding Tool with Tokens... ======");
  await ERC20ContractInstance.loadUpContract(RewardingToolAddress);
  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  const RT_MGS = await ERC20ContractInstance.balanceOf(RewardingToolAddress);
  console.log(
    "| Rewarding Tool's MGS Balance: ",
    formatTokenAmount(await RT_MGS),
    " MGS"
  );
  console.log();
  console.log("-----------------------------------------------------------");

  console.log();
  console.log("====== All Operations Completed Successfully! ======");
  console.log();
  console.log();
  console.log("====== Commencing Testing ======");
  console.log();

  const oldBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log(
    "| Deployer's Old MGS Balance: ",
    formatTokenAmount(await oldBalance),
    " MGS"
  );

  //   const amountToApprove = hre.ethers.parseEther("1000"); // Change this to the amount you want
  console.log();
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);
  //   await ERC20ContractInstance.approve(RewardingToolAddress, amountToApprove);
  const RewardingContractWithSigner = RewardingToolContract.connect(deployer);
  const RewardingContractWithManager = RewardingToolContract.connect(manager);

  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  console.log("Creating 2 User Objects inside the Rewarding Contract...");
  console.log("   1. (Souvlaki_Destroyer): The Contracts' Deployer ");
  console.log("   2. (Pizza_Manager): The HardHat's 2nd Account ");
  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  await RewardingContractWithSigner.createUser("Souvlaki_Destroyer");
  await RewardingContractWithManager.createUser("Pizza_Manager"); // TODO: Manager Needs CASH!
  console.log();
  console.log("-----------------------------------------------------------");

  const user = await RewardingContractWithSigner.users(deployer);

  // Note: Only the Owner can assign Managers!
  console.log("-----------------------------------------------------------");
  console.log();
  console.log(
    "Simulating that User: (Deployer) is performing the following actions:"
  );
  console.log(
    "   1. (Contract) User Creation: 10 MGS - (This automatically, when a user is created"
  );
  console.log("   1. (Forum) Comment Submission: 100 MGS");
  console.log("   2. (Forum) Comment Voting: 30 MGS");
  console.log("   3. (Forum) Post Voting: 50 MGS");
  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  console.log("User should have +190 more MGS Tokens...");
  console.log();
  console.log("-----------------------------------------------------------");

  await RewardingToolContractInstance.addPoints("forum", "submitComment");
  await RewardingToolContractInstance.addPoints("forum", "voteOnComment");
  await RewardingToolContractInstance.addPoints("forum", "voteOnPost");

  const newBalance = await ERC20ContractInstance.balanceOf(deployer);
  console.log();
  console.log(
    "| Deployer's New MGS Balance: ",
    formatTokenAmount(newBalance),
    " MGS"
  );
  console.log();

  console.log("*************************************************");
  console.log();
  console.log("====== Retrieving User Data ======");
  console.log();
  console.log("*************************************************");

  await RewardingContractWithSigner.assignManagerRole(manager.address);

  // Making the User with the address residing in the "manager" variable a Manager
  const managerObj = await RewardingContractWithManager.users(manager);

  // Owner
  console.log();
  console.log("User's Name: ", user[2]);
  console.log("User's ID: ", ethers.getNumber(user[0]));
  console.log("User's Address: ", user[1]);
  console.log("User's Access Level: ", user[3] === "" ? "none" : user[3]);
  console.log();
  console.log("===============================================");

  // Manager
  console.log();
  console.log("User's Name: ", managerObj[2]);
  console.log("User's ID: ", ethers.getNumber(managerObj[0]));
  console.log("User's Address: ", managerObj[1]);
  console.log(
    "User's Access Level: ",
    managerObj[3] === "" ? "none" : managerObj[3]
  );
  console.log();

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
