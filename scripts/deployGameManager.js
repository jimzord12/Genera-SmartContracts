const hre = require("hardhat");
const { ethers } = require("hardhat");
const fs = require("fs"); // Node.js file system module for reading files
const path = require("path");

async function main() {
  const [deployer, manager] = await ethers.getSigners();

  const gameManagerContract = await hre.ethers.deployContract(
    "GameManager",
    [],
    {}
  );

  await gameManagerContract.waitForDeployment();
  const gameManagerAddress = gameManagerContract.target;
  console.log(
    "| GameManager was successfully deployed at:",
    gameManagerAddress
  );

  // const gameManagerABIPath = path.resolve(
  //   __dirname,
  //   "../artifacts/contracts/GameManager.sol/GameManager.json"
  // );
  // const gameManagerABI = JSON.parse(fs.readFileSync(gameManagerABIPath)).abi;

  const contractAddresses = await import("../deployedContracts.json", {
    assert: { type: "json" },
  });
  const newJSON = {
    ...contractAddresses.default,
    GameManagerAddress: gameManagerAddress,
  };

  fs.writeFileSync(
    path.resolve(__dirname, "../deployedContracts.json"),
    JSON.stringify(newJSON, null, 2)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
