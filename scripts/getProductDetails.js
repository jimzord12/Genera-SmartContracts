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
  console.log("====== Getting Product Details ======");

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

  const userInput = await askQuestion("Product ID: ");

  console.log("-----------------------------------------------------------");
  console.log();
  console.log(`====== Fetching Product's #(${userInput})... ======`);
  const prodFetch_Tx = await RewardingToolContractInstance.products(
    Number(userInput)
  );

  // Converting Data to more human-readable format
  const convertedData = {
    id: Number(prodFetch_Tx[0]),
    name: prodFetch_Tx[6],
    location: prodFetch_Tx[7],
    price: Number(prodFetch_Tx[1]) / 100,
    amount: Number(prodFetch_Tx[2]),
    isEmpty: prodFetch_Tx[3],
    isInfinite: prodFetch_Tx[4],
    isDisabled: prodFetch_Tx[5],
  };

  console.log();
  console.log("-----------------------------------------------------------");
  console.log();
  console.log(convertedData);
  console.log();
  console.log("-----------------------------------------------------------");
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
