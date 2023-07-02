require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.19",
// };

module.exports = {
  solidity: "0.8.19",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      gas: "auto", // Automatically estimate the gas and provide a buffer
      gasPrice: "auto", // Automatically estimate the gas price
    },
    genera: {
      url: "http://83.212.81.174:8545",
      chainId: 20231,
      accounts: [
        process.env.ADMIN_PRIVATE_KEY,
        process.env.MANAGER_PRIVATE_KEY,
      ], // Set your private key here
      gas: "auto", // Automatically estimate the gas and provide a buffer
      gasPrice: "auto", // Automatically estimate the gas price
    },
  },
};
