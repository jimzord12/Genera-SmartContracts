// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyGreenScore is ERC20 {
    constructor() ERC20("MyGreenScore", "MGS") {
        _mint(address(this), 1000000 * (10 ** uint256(decimals())));
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}
