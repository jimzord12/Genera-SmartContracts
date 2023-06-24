const { ethers } = require("hardhat");
const axios = require("axios");

// 🧪 How to run the test! 🧪
/*
  1. open terminal (term_1): npx hardhat node
  2. open a new terminal (term_2): npx hardhat clean (Skip if no changes at Smart Contracts)
  3. term_2: npx hardhat compile (Skip if no changes at Smart Contracts)
  4. term_2: npx hardhat run --network localhost scripts/deployContracts.js
  5. open a new terminal (term_3): npx hardhat run --network localhost scripts/tests/redeemerValidator_2.js
*/

async function getRandomNumber() {
  try {
    const response = await axios.get("http://localhost:3033/random-number");
    console.log(response.data.randomNumber);
    return response.data.randomNumber;
  } catch (error) {
    console.error("Error:", error);
  }
}

async function main() {
  // Hardhat's Local Node Provider
  const provider = new ethers.JsonRpcProvider(
    "http://127.0.0.1:8545/" // HardHat Local's URL
    //   "http://83.212.81.174:8545" // GENERA's URL
  );

  let randomNumber;

  // Easy and convenient way to get HardHat's Accoutnts
  const [deployer, mykonos] = await ethers.getSigners();

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
  const RewardingContract_Mykonos = RewardingToolcontract.connect(mykonos);

  const MGScontractWithSigner = MGScontract.connect(deployer);

  // Call the smart contract's function to see what is the 1st Product
  const tx = await RewardingContractWithSigner.products(3);
  console.log("-----------------------------------------");
  console.log("TX_0 :  ", tx);
  console.log("-----------------------------------------");
  console.log();

  try {
    const tx_1 = await RewardingContractWithSigner.createUser(
      "Souvlaki_Destroyer"
    );
    console.log("TX_1.1, Creating a User (Souvlaki_Destroyer)...:  ");
    console.log();
    console.log("-----------------------------------------");
    console.log(tx_1);
    console.log("-----------------------------------------");
    console.log();

    // Wait for the transaction to be mined
    const receipt = await tx_1.wait();
    console.log("=== Transaction (1.1) was executed! ===");
    console.log();
    // Check the transaction status
    if (receipt.status === 1) {
      console.log();
      console.log("=== User (Souvlaki_Destroyer) created successfully ===");
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

  try {
    const tx_1 = await RewardingContract_Mykonos.createUser(
      "Waiter_In_Mykonos"
    );
    console.log("TX_1.2, Creating a Manager (Waiter_In_Mykonos)...:  ");
    console.log();
    console.log("-----------------------------------------");
    console.log(tx_1);
    console.log("-----------------------------------------");
    console.log();

    // Wait for the transaction to be mined
    const receipt = await tx_1.wait();
    console.log("Transaction (1.2) was executed!");
    // Check the transaction status
    if (receipt.status === 1) {
      console.log("=== Manager (Waiter in Mykonos) created successfully ===");
    } else {
      console.log("User Creation Transaction failed");
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

  try {
    console.log();
    console.log(
      "Simulating User's Approval for the Rewarding Tool to subtract some of his/her MGS Tokens"
    );
    console.log();
    await tx_1_MGS.wait();
  } catch (error) {
    console.log();
    console.log("We got this error while trying to (Get Spent Approval): ");
    console.log();
  }

  // Trying to Claim it...
  try {
    console.log();
    console.log("-----------------------------------------");
    console.log("Waiting for the Random Number to be sent to the Oracle...");
    console.log("-----------------------------------------");
    console.log();

    randomNumber = await getRandomNumber();
    console.log();
    console.log("-----------------------------------------");
    console.log(`The Oracle's random number is: ${randomNumber}`);
    console.log("-----------------------------------------");
    console.log();

    const tx_2 = await RewardingContractWithSigner.productClaimer(3);
    console.log(
      "TX_2, User (Souvlaki_Destroyer), Is trying to Claim Product #4:  "
    );
    console.log();
    console.log("-----------------------------------------");
    console.log(tx_2);
    console.log("-----------------------------------------");
    console.log();
  } catch (error) {
    console.log("We got this error while trying to (Claim a Product): ");
    console.log();
    console.log(error);
    console.log();
  }

  // Trying to Claim it...
  const tx_3 = await RewardingContractWithSigner.viewYourUnclaimedProds();
  console.log(
    "TX_3, User (Souvlaki_Destroyer), Is viewing his/her Unclaimed Rewards:  "
  );
  console.log();
  console.log("-----------------------------------------");
  console.log(tx_3);
  console.log("-----------------------------------------");
  console.log();

  // Giving "Manager" Level Access to the Waiter in Mykonos
  // (Souvlaki_Destroyer) happens to be the Contract's Owner xD
  try {
    const managerMaking = await RewardingContractWithSigner.assignManagerRole(
      mykonos.address
    );
    console.log(
      "TX_4, User (Souvlaki_Destroyer), Is trying Make (Mykonos) a Manager:  "
    );
    console.log();
    console.log("-----------------------------------------");
    console.log(managerMaking);
    console.log("-----------------------------------------");
    console.log();
  } catch (error) {
    const howIsOwner = await RewardingContractWithSigner.owner();
    const roleChecking = await RewardingContractWithSigner.checkOwnerRole(
      deployer
    );
    console.log(
      "We got this error while (Souvlaki_Destroyer) was trying to (Make Mykonos a Manager): "
    );
    console.log();
    console.log(error);
    console.log();
    console.log("-----------------------------------------");
    console.log();
    console.log("This is the Contract Owner: ", howIsOwner);
    console.log("Does (Souvlaki_Destroyer) has Owner Role: ", roleChecking);
  }

  // Trying to call redeemerValidator to confirm the Product and give it to User...
  try {
    const tx_2 = await RewardingContract_Mykonos.redeemerValidator(
      "Souvlaki_Destroyer",
      randomNumber,
      0
    );
    console.log("TX_5, Trying see if Waiter should give free meal:  ");
    console.log();
    console.log("-----------------------------------------");
    console.log(tx_2);
    console.log("-----------------------------------------");
    console.log();
    // Wait for the transaction to be mined
    const receipt = await tx_2.wait();
    console.log("=== Transaction (1.1) was executed! ===");
    console.log();
    // Check the transaction status
    if (receipt.status === 1) {
      console.log();
      console.log("=== User (Souvlaki_Destroyer) Can Enjoy The Meal! :D ===");
      console.log();
    } else {
      console.log();
      console.log("=== User (Souvlaki_Destroyer) Shall strave :'( ===");
      console.log();
    }
  } catch (error) {
    const user_1 = await RewardingContract_Mykonos.userNames(
      "Souvlaki_Destroyer"
    );
    const user_2 = await RewardingContract_Mykonos.userNames(
      "Waiter_In_Mykonos"
    );
    console.log(
      "We got this error while (Mykonos Waiter) was trying to (Validate User Reward): "
    );
    console.log();
    console.log(error);
    console.log();
    console.log("-----------------------------------------");
    console.log();
    console.log("User 1: ", user_1);
    console.log();
    console.log("User 2: ", user_2);
    console.log();
    console.log("-----------------------------------------");
  }

  console.log("====== End of Test ======");
  console.log();
  console.log("|> Should get <|");
  console.log();
  console.log("|> 1. === User (Souvlaki_Destroyer) Can Enjoy The Meal! :D ===");
  console.log();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
