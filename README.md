# Genera-SmartContracts
GENERA Project: Web3 (Blockchain) Backend Logic

## What is a Smart Contract?
A smart contract is a self-executing contract with terms of the agreement directly written into code. 
<br />
It automatically performs transactions when predefined conditions are met, without the need for intermediaries.
<br /> 
It is typically built on blockchain technology, ensuring transparency, security, and efficiency.
<br />

## Platform's Smart Contracts
Currently, our platform utilizes 2 Smart Contracts.
- RewardingTool.sol
- GameManager.sol

### RewardingTool

#### Contract Connection Data
- Address: 0x300302fEc3D905eb66Cb7743C636F8741B72dB3a
- Network: GENERA (Chain ID: 20231)
- ABI: [click here](https://github.com/jimzord12/Genera-SmartContracts/blob/main/rewardingABI.json)

#### Description
This Contract is tasked with the purpose of issuing and removing (burning) MGS (MyGreenScore) Tokens.
<br />
These tokens are used a way to motivate users to explore and utilize the platform's web applications.
<br />
Users can accumulate these tokens by performing specific actions or tasks.

#### For Devs 👨‍💻
***How to use the Contract***
<br />
Firstly, you have to insert/import a JavaScript Library in your Frontend that can interact with Blockchain Networks.
<br />
The most popular choices are:
- ethers.js
- web3.js
However, nowdays more abstract libraries exist that make this process event easier (ex. wagmi react hooks)
