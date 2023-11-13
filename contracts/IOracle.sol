// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOracle {
    function randomNumber() external view returns (uint32);

    function updateRandomNumber(uint32 _randomNumber) external;
}
