// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyGreenScore is ERC20 {
    constructor() ERC20("MyGreenScore", "MGS") {
        _mint(address(this), 1000000 * (10 ** uint256(decimals()))); // This is how much the contract gets
        _mint(msg.sender, 500 * (10 ** uint256(decimals()))); // This is the MGS Token that the Deployer gets
    }

    function loadUpRewardingTool(address _addr) public {
        //TODO: ULTRA INSECURE!!!
        _mint(_addr, 2000000 * (10 ** uint256(decimals()))); // This is how much the Rewarding contract gets
    }
}
