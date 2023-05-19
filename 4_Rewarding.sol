// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

contract RewardingTool {
    // Contract Address (Goerli): 0x30871850bc6c12A6edaB4896416a137ef4c72946
    // -- Global Score - START
    uint public baseReward;
    address public contractAddress;

    mapping(address => User) public users;
    mapping(string => Service) public services;

    uint public numUsers;
    uint public numServices;

    // -- Global Score- END

    constructor() {
        baseReward = 10; // Applying a default value
        contractAddress = address(this);
    }

    // -- Structs Section - START
    struct User {
        uint id;
        uint totalPoints; 
        address wallet;
        // Service => MGS Score Points (Ex. forum => 250)
        mapping(string => uint) pointsPerService;
    }

    struct ServiceEvent { // Ex. It can be a Comment, Vote, etc.
        uint id;
        uint totalPoints;
        string name;
        uint64 rewardMulti;
        // mapping(uint => uint) rewardMulti;

    }

    struct Service { // Ex. It can be the Social Forum, Web Game, etc.
        uint id;
        string name;
        uint totalEvents;
        // Service Event ID => MGS Score Points (Ex. Comment => baseReward * Multi)
        mapping(string => ServiceEvent) events; // Can be used for Statistics on the WebSite (Ex. 163.045 Points has been issued from  Comment Submitions 
    }

    // -- Structs Section - END

    // -- Actions - START
    //       addPoints(             ,                      forum,  comment                 )
    function addPoints(string calldata _serviceName, string calldata _eventName) public returns (bool) {
        /**
        * ⚒ Make Modifiers for arg checking: Like if Event and Service exist
        *
        */
        User storage current_user = users[msg.sender]; // Get the User from his/her address
        Service storage current_service = services[_serviceName]; // Get the Service from payload
        ServiceEvent storage current_event = current_service.events[_eventName]; // Get the Event from the Service and payload

        // 1. Find out how much points to give | Calc Reward
        uint reward = pointsCalc(current_event.rewardMulti);

        // 2. Increase User's Total Points
        current_user.totalPoints += reward;

        // 3. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] += reward;

        // 4. Store the points conserning the specific Service & Event (For Statistic Reasons)
        current_event.totalPoints += reward;

        return true; // Indicates that the function was executed successfully

    }

    function redeemer(uint _productPrice, string calldata _serviceName) public returns (bool) {
        User storage current_user = users[msg.sender]; // Get the User from his/her address
        
        // 1. Decrease User's Total Points
        current_user.totalPoints -= _productPrice;

        // 2. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] -= _productPrice;

        return true; // Indicates that the function was executed successfully
    }

    function setBaseReward(uint _initValue) public returns (bool) {
        baseReward = _initValue;

        return true; // Indicates that the function was executed successfully
    }

    // -- Actions - END

    // -- CRUD Operations - START
    function createUser() public returns (bool) {
        // Check if user already exists
        require(users[msg.sender].id >= numUsers, "User already exists");

        // 1. Intialize the new user by accessing the "users" mapping
        User storage newUser = users[msg.sender];

        // 2. Intialize the new user's properties
        newUser.id = numUsers;
        newUser.totalPoints = 0;
        newUser.wallet = msg.sender;

        // 2. Increament the "numUsers" so that we know:
        //   - How many users exist
        //   - Generate their IDs
        numUsers += 1;

        return true; // Indicates that the function was executed successfully

    }

    function createService(string calldata _serviceName) public returns (bool) {
        Service storage newService = services[_serviceName];

        require(bytes(newService.name).length == 0, "Service already exists");

        newService.id = numServices;
        newService.totalEvents = 0;
        newService.name = _serviceName;

        numServices += 1;

        return true; // Indicates that the function was executed successfully
    }

    // Ex. eventCreator('CommentSubmission', 1, 1)
    function createEvent(string calldata _eventName, string calldata _serviceName, uint64 _multiplier) public returns (bool) {
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];

        require(bytes(current_event.name).length == 0, "Event already exists");

        /**
            uint id;
            uint totalPoints;
            string calldata name;
            uint64 rewardMulti;
        */

        current_event.id = current_service.totalEvents;
        current_event.totalPoints = 0;
        current_event.name = _eventName;
        current_event.rewardMulti = _multiplier;

        current_service.totalEvents += 1;

        return true; // Indicates that the function was executed successfully

    }

    // -- CRUD Operations - END

    // -- Utility Functions - START
    function pointsCalc(uint _multiplier) public view returns (uint) {
        return baseReward * _multiplier;
    } 

    // -- Utility Functions - END

    // -- Getter Functions - START
    function viewEvent(string calldata _serviceName, string calldata _eventName) public view returns (ServiceEvent memory) {
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];
        return current_event;
    }

    function viewUserPoints(address _userAddr) public view returns (uint) {
        User storage current_user = users[_userAddr]; // Getting the requested user by using his/her wallet address
        return current_user.totalPoints;
    }

    function viewYourPoints() public view returns (uint) {
        User storage you = users[msg.sender]; // Getting the requested user by using his/her wallet address
        return you.totalPoints;

    }

    // -- Getter Functions - END


}