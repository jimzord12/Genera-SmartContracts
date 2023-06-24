const { ethers } = require("hardhat");

// 🧪 How to run the test! 🧪
/*
  1. open terminal (term_1): npx hardhat node
  2. open new terminal (term_2): npx hardhat clean
  3. term_2: npx hardhat compile
  4. term_2: npx hardhat run --network localhost scripts/deployContracts.js
  5. open a new terminal (term_3): npx hardhat run --network localhost scripts/tests/claimProduct_2.js
  5. Should get:
    1. TX_1 :   Result(8) [
          0n,
          10n,
          1n,
          false,
          true,
          false,
          'ToGameGoldConversion',
          'N/A'
        ]
    2. reverted with reason string 'You (the Tx sender), do not have an account, create one first.'
*/

async function main() {
  // Hardhat's Local Node Provider
  const provider = new ethers.JsonRpcProvider(
    "http://127.0.0.1:8545/" // HardHat Local's URL
    //   "http://83.212.81.174:8545" // GENERA's URL
  );

  // Easy and convenient way to get HardHat's Accoutnts
  const [deployer] = await ethers.getSigners();

  // Rewarding Tool's Address
  const contractAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

  // Rewarding Tool's ABI
  const abi =
    require("../../artifacts/contracts/RewardingTool.sol/RewardingTool.json").abi; // Replace with your contract's ABI

  const contract = new ethers.Contract(contractAddress, abi, provider);
  //   const wallet = new ethers.Wallet(privateKey, provider);
  //   const signer = wallet.connect(contract.provider);

  // Call the smart contract's function to see what is the 1st Product
  const tx = await contract.connect(deployer).products(0);
  console.log("TX_1 :  ", tx);
  console.log();

  // Trying to Claim it...
  const tx_1 = await contract.connect(deployer).productClaimer(0);
  console.log("Can I claim it? :  ", tx_1);
  console.log();

  console.log("====== End of Test ======");
  console.log();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
