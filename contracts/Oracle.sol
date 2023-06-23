// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract Oracle {
    uint32 public randomNumber;

    function updateRandomNumber(uint32 _randomNumber) public {
        // This function should have adequate controls to prevent unauthorized updates
        randomNumber = _randomNumber;
    }
}
