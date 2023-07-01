const hre = require("hardhat");
const { ethers } = require("hardhat");
const fs = require("fs"); // Node.js file system module for reading files
const path = require("path");
const readline = require("readline");

const { getAddresses } = require("./getAddresses");

function askQuestion(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans);
    })
  );
}

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
  const [deployer, manager] = await ethers.getSigners();

  console.log();
  console.log("====== Getting User Details ======");

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
  const RewardingToolPath = path.resolve(
    __dirname,
    "../artifacts/contracts/RewardingTool.sol/RewardingTool.json"
  );

  // Getting the ABI's using the Paths
  const ERC20ABI = JSON.parse(fs.readFileSync(ERC20Path)).abi;
  const OracleABI = JSON.parse(fs.readFileSync(oraclePath)).abi;
  const ServicesABI = JSON.parse(fs.readFileSync(servicesPath)).abi;
  const RewardingToolABI = JSON.parse(fs.readFileSync(RewardingToolPath)).abi;

  // Getting the Contracts' Addresses
  const contractAddresses = getAddresses();

  // 1. Create contract instances: ERC20
  const ERC20ContractInstance = new ethers.Contract(
    contractAddresses.ERC20ContractAddress,
    ERC20ABI,
    deployer
  );

  // 2. Create contract instances: Oracle
  const OracleContractInstance = new ethers.Contract(
    contractAddresses.OracleContractAddress,
    OracleABI,
    deployer
  );

  // 3. Create contract instances: Services
  const ServicesContractInstance = new ethers.Contract(
    contractAddresses.ServicesContractAddress,
    ServicesABI,
    deployer
  );

  const RewardingToolContractInstance = new ethers.Contract(
    contractAddresses.RewardingToolAddress,
    RewardingToolABI,
    deployer
  );

  ////////////////////////  ==  This is typical Intialization  ==  /////////////////////////

  const userInput = await askQuestion("User's Name: ");

  console.log("-----------------------------------------------------------");
  console.log();
  console.log(`====== Fetching User's #(${userInput})... ======`);

  const userAddress = await RewardingToolContractInstance.userNames(userInput);
  const userDetails = await RewardingToolContractInstance.users(userAddress);

  if (userDetails[2] === "") {
    console.log();
    console.log(" ❌ ⛔ ❌ ⛔ ❌ ⛔ ❌ ⛔ ❌ ⛔ ❌ ⛔ ❌ ⛔ ");
    console.log();
    throw new Error("This User doesn't exist, you probably made a typo 😋");
  }

  const userPendingProds =
    await RewardingToolContractInstance.getPendingProducts(userAddress);

  const convertedRawData = userPendingProds.map((pendingProd) => {
    return {
      pendindProdID: Number(pendingProd[0]),
      prodID: Number(pendingProd[1]),
      collectionHash: pendingProd[2],
      isRedeemed: pendingProd[3],
    };
  });

  //   Converting Data to more human-readable format
  let convertedData = {
    id: Number(userDetails[0]),
    address: userDetails[1],
    name: userDetails[2],
    accessLevel: userDetails[3],
    pendingRewards: convertedRawData,
  };

  console.log(
    `====== Fetching User's #(${userInput} Pending Products... ======`
  );

  //   console.log();
  //   console.log("-----------------------------------------------------------");
  //   console.log();
  //   console.log(userDetails);
  //   console.log();
  //   console.log("-----------------------------------------------------------");

  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  console.log(convertedData);
  console.log();
  console.log("-----------------------------------------------------------");

  function consolidateRewards(convertedData) {
    let consolidatedRewards = {};

    convertedData.forEach((reward) => {
      if (consolidatedRewards[reward.prodID]) {
        consolidatedRewards[reward.prodID].amount += 1;
      } else {
        consolidatedRewards[reward.prodID] = {
          productID: reward.prodID,
          amount: 1,
        };
      }
    });

    // convert the object to an array
    consolidatedRewards = Object.values(consolidatedRewards);

    return consolidatedRewards;
  }

  console.log();
  console.log("===========================================================");
  console.log("Testing GPT-4 Function");
  console.log("===========================================================");
  console.log();
  console.log(consolidateRewards(convertedData.pendingRewards));
  console.log();
  console.log("-----------------------------------------------------------");

  //   console.log();
  //   console.log("-----------------------------------------------------------");
  //   console.log();
  //   console.log(userPendingProds);
  //   console.log();
  //   console.log("-----------------------------------------------------------");
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
