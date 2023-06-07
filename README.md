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
These tokens are used as way to motivate users to explore and utilize the platform's web services.
<br />
Users can accumulate these tokens by performing specific actions or tasks.
<br />
<br />

#### For Devs 👨‍💻

<br />

**_Contract's API_**
<br />

- Write (State alterating) functions:

  ```javascript
  function addPoints(string _serviceName, string _eventName) public returns (bool)
  ```

  ```javascript
  function createUser(string _name) public returns (bool)
  ```

  ```javascript
  function createService(string  _serviceName) public returns (bool)
  ```

  ```javascript
  function createEvent(string _eventName, string _serviceName, uint64 _multiplier) public returns (bool)
  ```

  ```javascript
  function setBaseReward(uint _initValue) public returns (bool)
  ```

  ```javascript
  function redeemer(uint _productPrice, string _serviceName) public returns (bool)
  ```

- Read/View (State non-alterating) functions:

  ```javascript
  Getters for: baseReward, contractAddress, numServices, numUsers, services, users
  ```

  ```javascript
  function viewYourPoints(string _serviceName, string _eventName) public returns (bool)
  ```

  ```javascript
  function viewEvent(string _serviceName, string _eventName) public view returns (ServiceEvent)
  ```

**_How to use the Contract_**
<br />

**_Step #1_**:
<br />
You have to insert/import a JavaScript Library in your Frontend that can interact with Blockchain Networks.
<br />
<br />
The most popular choices are:

- ethers.js
- web3.js

<br />
However, nowdays more abstract libraries exist that make this process event easier (ex. wagmi react hooks)
<br />
Once, this step is completed you should have a Contract instance that the library constructed based on the
<br />
address and ABI you provided as arguments.
<br />
<br />

**_Step #2_**:
<br />
Create a **Service** Object and its **Events** in the Smart Contract.
<br />
For example, a Service could be: "MOOC" and one of its Events could be: "videoWathced"
<br />

This step is a bit **tricky**, because it is not similar to how frontend development works.
<br />
This is because the Smart Contract's storage is not limited to only memory
<br />
(meaning that it will be erased when the user closes the browser tab or window).
<br />
Most of the time, we need to permanetly store information.
<br />
The easiest way to create these Service and Event objects is through the [Remix IDE](https://remix.ethereum.org)
<br />

This video demonstrates how to perform the mentioned operations: [emptyVideoLink]()
<br />

<br />

**_Step #3_**:
<br />
Finally, the only thing left to do is to call the contract's functions whenever you need them in your code, for example:
<br />

```javascript
function sumbitComment() {
  // Your previous code...
  // Supposing your Contract Instance name is "rewardContract"
  // This example uses ethers.js v5.7.2 syntax, but web3.js is very similar
  const { wasSuccessful } = await rewardContract.addPoints("MOOC", "videoWathced");
<br />
  if(!wasSuccessful) throw new Error("Contract Interaction Failed!")
  // The rest of your code...
}
```

<br />

### GameManager

#### Contract Connection Data

- Address:
- Network: GENERA (Chain ID: 20231)
- ABI: [click here](https://github.com/jimzord12/Genera-SmartContracts/blob/main/gameABI.json)

#### Description

This Contract creates and transfers NFT representations of the Game's Cards.
<br />
It's using the OpenZeppelin's ERC-1155 Token Standard which is
<br />
one of the most battletested and trusted Solidty Open-source Libraries.

#### For Devs 👨‍💻

**_How to use the Contract_**
<br />

**_Step #1_**:
<br />
You have to insert/import a JavaScript Library in your Frontend that can interact with Blockchain Networks.
<br />
<br />
The most popular choices are:

- ethers.js
- web3.js

<br />
However, nowdays more abstract libraries exist that make this process event easier (ex. wagmi react hooks)
<br />
Once, this step is completed you should have a Contract instance that the library constructed based on the
<br />
address and ABI you provided as arguments.
<br />
<br />

**_Step #2_**:
<br />
Call the createPlayer() contract function in the same place where your Player creation happens.
<br />

```javascript
async function createNewPlayer(playerData) {
  axios.post('https://your-web-server/players', playerData)
  .then((response) => {
      if (response.ok === true) {
          try {
              // The Player's ID from the server is required so that
              // the Contract and the Server stay in sync
              await gameContract.createPlayer(playerData.name, response.newPlayer.id)
          } catch {
              // Important! Here you must find way to a handle the edge case where
              // the server-side player is created successfully, but the one in the
              // Smart Contract fails! And vice versa
              console.error("Problem occured in the Blockchain when creating new player");
          }
      }
  })
  .catch((error) => {
      console.error(error);
  });
}
```

For example, a Service could be: "MOOC" and one of its Events could be: "videoWathced"
<br />

This step is a bit **tricky**, because it is not similar to how frontend development works.
<br />
This is because the Smart Contract's storage is not limited to only memory
<br />
(meaning that it will be erased when the user closes the browser tab or window).
<br />
Most of the time, we need to permanetly store information.
<br />
The easiest way to create these Service and Event objects is through the [Remix IDE](https://remix.ethereum.org)
<br />

This video demonstrates how to perform the mentioned operations: [emptyVideoLink]()
<br />

<br />

**_Step #3_**:
<br />
Finally, the only thing left to do is to call the contract's functions whenever you need them in your code, for example:
<br />

```javascript
function sumbitComment() {
  // Your previous code...
  // Supposing your Contract Instance name is "rewardContract"
  // This example uses ethers.js v5.7.2 syntax, but web3.js is very similar
  const { wasSuccessful } = await rewardContract.addPoints("MOOC", "videoWathced");
<br />
  if(!wasSuccessful) throw new Error("Contract Interaction Failed!")
  // The rest of your code...
}
```

<br />
````
