// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RewardingTool {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public contractAddress;

    mapping(address => User) public users;
    mapping(string => Service) public services;

    uint public numUsers;
    uint public numServices;

    constructor(IERC20 _token) {
        token = _token;
        contractAddress = address(this);

        // Same initializations as before...
    }

    // Updated structs...
    struct User {
        uint id;
        address wallet;
        string name;
        mapping(string => uint) pointsPerService;
    }

    // Other structs remain the same...

    // Updated methods...
    function addPoints(
        string memory _serviceName,
        string memory _eventName,
        uint _tokens
    ) public returns (bool) {
        User storage current_user = users[msg.sender];
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];

        uint reward = pointsCalc(current_event.rewardMulti, _tokens);

        // Instead of increasing an internal point system, we now use the token.transferFrom function to
        // move tokens from the user to the contract.
        // The user must have approved the contract to spend the tokens beforehand.
        token.safeTransferFrom(msg.sender, contractAddress, reward);

        current_user.pointsPerService[_serviceName] += reward;
        current_event.totalPoints += reward;

        emit PointsGained(msg.sender, reward);

        return true;
    }

    // Update addPointsTo and redeemer in a similar way...

    function pointsCalc(
        uint _multiplier,
        uint _tokens
    ) public pure returns (uint) {
        return _multiplier * _tokens;
    }

    // The rest of the code remains unchanged...
}
