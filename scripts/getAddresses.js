const fs = require("fs");
const path = require("path");

const contractAddresses = JSON.parse(
  fs.readFileSync(path.resolve(__dirname, "../deployedContracts.json"))
);

console.log(
  "Contract addresses retrieved from 'deployedContracts.json':",
  contractAddresses
);

function getAddresses() {
  return contractAddresses;
}

module.exports = { getAddresses };
