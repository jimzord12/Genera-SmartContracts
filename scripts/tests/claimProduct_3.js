const { ethers } = require("hardhat");

// 🧪 How to run the test! 🧪
/*
  1. open terminal (term_1): npx hardhat node
  2. open a new terminal (term_2): npx hardhat clean (Skip if no changes at Smart Contracts)
  3. term_2: npx hardhat compile (Skip if no changes at Smart Contracts)
  4. term_2: npx hardhat run --network localhost scripts/deployContracts.js
  5. open a new terminal (term_3): npx hardhat run --network localhost scripts/tests/claimProduct_3.js
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
  const RewardingToolAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const MGSAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  // Rewarding Tool's ABI
  const RT_abi =
    require("../../artifacts/contracts/RewardingTool.sol/RewardingTool.json").abi;

  // MyGreenScore's ABI
  const MGS_abi =
    require("../../artifacts/contracts/MyGreenScore.sol/MyGreenScore.json").abi;

  const RewardingToolcontract = new ethers.Contract(
    RewardingToolAddress,
    RT_abi,
    provider
  );

  const MGScontract = new ethers.Contract(MGSAddress, MGS_abi, provider);

  const RewardingContractWithSigner = RewardingToolcontract.connect(deployer);

  const MGScontractWithSigner = MGScontract.connect(deployer);

  // Call the smart contract's function to see what is the 1st Product
  const tx = await RewardingContractWithSigner.products(0);
  console.log("TX_0 :  ", tx);
  console.log();

  try {
    const tx_1 = await RewardingContractWithSigner.createUser(
      "Souvlaki_Destroyer"
    );
    console.log("TX_1, Creating a User...:  ", tx_1);
    console.log();

    // Wait for the transaction to be mined
    const receipt = await tx_1.wait();
    console.log("=== Transaction was executed! ===");
    console.log();
    // Check the transaction status
    if (receipt.status === 1) {
      console.log();
      console.log("=== User created successfully ===");
      console.log();
    } else {
      console.log();
      console.log("=== User Creation Transaction failed ===");
      console.log();
    }
  } catch (error) {
    console.log("We got this error while trying to (Create a User): ");
    console.log();
    console.log(error);
    console.log();
  }

  const amountToApprove = ethers.parseUnits("1000.0", 18);
  const tx_1_MGS = await MGScontractWithSigner.approve(
    RewardingToolAddress,
    amountToApprove
  );

  await tx_1_MGS.wait();

  // Trying to Claim it...
  try {
    const tx_2 = await RewardingContractWithSigner.productClaimer(0);
    console.log("TX_2, Trying to Claim it:  ", tx_2);
    console.log();
  } catch (error) {
    console.log("We got this error while trying to (Claim a Product): ");
    console.log();
    console.log(error);
    console.log();
  }

  // Trying to Claim it...
  const tx_3 = await RewardingContractWithSigner.viewYourUnclaimedProds();
  console.log("TX_3, Viewing Your Unclaimed Rewards:  ", tx_3);
  console.log();

  console.log("====== End of Test ======");
  console.log();
  console.log("|> Should get <|");
  console.log();
  console.log("|> 1. Transaction was executed!");
  console.log();
  console.log("|> 2. User created successfully");
  console.log();
  console.log(
    "|> 3. TX_3, Viewing Your Unclaimed Rewards: Result(1) [Result(4)]"
  );
  console.log();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
