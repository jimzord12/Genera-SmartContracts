const { ethers } = require("hardhat");

// 🧪 How to run the test! 🧪
/*
  1. open terminal (term_1): npx hardhat node
  2. open a new terminal (term_2): npx hardhat clean (Skip if no changes at Smart Contracts)
  3. term_2: npx hardhat compile (Skip if no changes at Smart Contracts)
  4. term_2: npx hardhat run --network localhost scripts/deployContracts.js
  5. open a new terminal (term_3): npx hardhat run --network localhost scripts/tests/claimProduct_2.js
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
  const contractWithSigner = contract.connect(deployer);

  // Listen for the UserCreation event
  // contractWithSigner.on("UserCreation", (numUsers, sender, name) => {
  //   console.log(
  //     `User ${name} was created successfully with ID ${numUsers} by ${sender}`
  //   );
  // });

  // Call the smart contract's function to see what is the 1st Product
  const tx = await contractWithSigner.products(0);
  console.log("TX_0 :  ", tx);
  console.log();

  try {
    const tx_1 = await contract
      .connect(deployer)
      .createUser("Souvlaki_Destroyer");
    console.log("TX_1, Creating a User...:  ", tx_1);
    console.log();

    // Wait for the transaction to be mined
    const receipt = await tx_1.wait();
    console.log("Transaction was executed!");
    // Check the transaction status
    if (receipt.status === 1) {
      console.log("User created successfully");
    } else {
      console.log("User Creation Transaction failed");
    }
  } catch (error) {
    console.log("We got this error while trying to (Create a User): ");
    console.log();
    console.log(error);
    console.log();
  }

  // Trying to Claim it...
  try {
    const tx_2 = await contractWithSigner.productClaimer(0);
    console.log("TX_2, Trying to Claim it:  ", tx_2);
    console.log();
  } catch (error) {
    console.log("We got this error while trying to (Claim a Product): ");
    console.log();
    console.log(error);
    console.log();
  }

  // Trying to Claim it...
  const tx_3 = await contractWithSigner.viewYourUnclaimedProds();
  console.log("TX_3, Viewing Your Unclaimed Rewards:  ", tx_3);
  console.log();

  console.log("====== End of Test ======");
  console.log();
  console.log("|> Should get <|");
  console.log();
  console.log("|> 1. Transaction was executed!");
  console.log();
  console.log();
  console.log("|> 2. User created successfully");
  console.log();
  console.log();
  console.log("|> 3. We got this error while trying to (Claim a Product):");
  console.log();
  console.log(
    "|> 4. Error: reverted with reason string 'ERC20: insufficient allowance'"
  );
  console.log();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
