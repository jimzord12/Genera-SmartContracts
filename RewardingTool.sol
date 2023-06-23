// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract RewardingTool {
    // Contract Address (GENERA - Network): 0x300302fEc3D905eb66Cb7743C636F8741B72dB3a
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public contractAddress;

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
        token = _token;

        // Just some automations cuz the contract is still under dev
        string[2] memory defaultServives = ["forum", "game"];
        string[3] memory defaultForumEvents = [
            "submitComment",
            "voteOnComment",
            "voteOnPost"
        ];
        uint8[3] memory defaultForumEventsMultis = [10, 3, 5];
        string[4] memory defaultGameEvents = [
            "TownHallUpgrade",
            "cardCreation",
            "successCardSale",
            "rankBased"
        ];
        uint8[4] memory defaultGameEventsMultis = [10, 3, 5, 1];

        for (uint i = 0; i < 2; i++) {
            string memory service = defaultServives[i];
            createServiceInternal(service);

            if (areEqual(service, "forum")) {
                for (uint j = 0; j < 3; j++) {
                    createEventInternal(
                        defaultForumEvents[j],
                        "forum",
                        defaultForumEventsMultis[j]
                    );
                }
            } else if (areEqual(service, "game")) {
                for (uint j = 0; j < 3; j++) {
                    createEventInternal(
                        defaultGameEvents[j],
                        "game",
                        defaultGameEventsMultis[j]
                    );
                }
            }
        }
    }

    // -- Events Section - START

    event UserCreation(
        uint indexed id,
        address indexed account,
        string indexed name
    ); // OK
    event ServiceCreation(uint indexed id, string indexed name); // OK
    event EventCreation(
        uint indexed id,
        string indexed name,
        string indexed serviceName
    ); // Ok
    event PointsGained(address indexed account, uint indexed amount); // OK
    event PointsRedeemed(
        address indexed account,
        string indexed serviceName,
        uint indexed _productPrice,
        uint _totalPoints_before
    ); // ok

    // -- Events Section - END

    // -- Structs Section - START

    struct Product {
        // Ex. It can be a physical, real or digital redeemable reward (brelock, in-game currency, free musceum tickets
        uint id;
        uint price;
        uint32 amount; // MAX_VALUE uint32, dec: 4,294,967,295 || hex: 0xFFFFFFFF
        bool isEmpty;
        bool isInfinite;
        string name;
        string location;
    }

    struct PendingProduct {
        uint id;
        uint productId;
        address amount;
        bytes32 collectionHash; // keccak256(username + productId + 6-digit nonce)
        // Service => MGS Score Points (Ex. forum => 250)
        mapping(string => uint) pointsPerService;
    }

    struct User {
        uint id;
        address walletAddr;
        string name;
        PendingProduct[] pendingProducts;
        // Service => MGS Score Points (Ex. forum => 250)
        mapping(string => uint) pointsPerService;
    }

    struct ServiceEvent {
        // Ex. It can be a Comment, Vote, etc.
        uint id;
        uint totalPoints;
        string name;
        uint64 rewardMulti;
        // mapping(uint => uint) rewardMulti;
    }

    struct Service {
        // Ex. It can be the Social Forum, Web Game, etc.
        uint id;
        string name;
        uint totalEvents;
        // Service Event ID => MGS Score Points (Ex. Comment => baseReward * Multi)
        mapping(string => ServiceEvent) events; // Can be used for Statistics on the WebSite (Ex. 163.045 Points has been issued from  Comment Submitions
    }

    // -- Structs Section - END

    // -- Actions - START
    //       addPoints(             ,                      forum,  comment                 )
    function addPoints(
        string memory _serviceName,
        string memory _eventName,
    ) public returns (bool) {
        User storage current_user = users[msg.sender];
        Service storage current_service = services[_serviceName]; // Get the Service from payload
        ServiceEvent storage current_event = current_service.events[_eventName]; // Get the Event from the Service and payload

        // 1. Find out how much points to give | Calc Reward
        uint reward = pointsCalc(current_event.rewardMulti);

        // 2. Increase User's Total Points
        token.safeTransferFrom(msg.sender, contractAddress, reward);
        // current_user.totalPoints += reward;

        // 3. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] += reward;

        // 4. Store the points conserning the specific Service & Event (For Statistic Reasons)
        current_event.totalPoints += reward;

        emit PointsGained(msg.sender, reward);

        return true; // Indicates that the function was executed successfully
    }

    function addPointsTo(
        string memory _serviceName,
        string memory _eventName,
        address _to,
        uint _reward
    ) public returns (bool) {
        User storage current_user = users[_to];
        Service storage current_service = services[_serviceName]; // Get the Service from payload
        ServiceEvent storage current_event = current_service.events[_eventName]; // Get the Event from the Service and payload

        // 1. Increase User's Total Points
        token.safeTransferFrom(msg.sender, contractAddress, reward);
        // current_user.totalPoints += _reward;

        // 2. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] += _reward;

        // 3. Store the points conserning the specific Service & Event (For Statistic Reasons)
        current_event.totalPoints += _reward;

        emit PointsGained(_to, _reward); // Emits the relevant event

        return true; // Indicates that the function was executed successfully
    }

    /**
     * Future: Also add the product to the Event
     */
    function redeemer(
        uint _productPrice,
        string memory _serviceName
    ) public returns (bool) {
        User storage current_user = users[msg.sender]; // Get the User from his/her address

        // 0. Get User's Total Points
        uint totalPoints = current_user.totalPoints;

        // 1. Decrease User's Total Points
        current_user.totalPoints -= _productPrice;

        // 2. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] -= _productPrice;

        // This Events says: Account X used the Y Service and spent Z Points. Before purchse had K TotalPoints
        emit PointsRedeemed(
            msg.sender,
            _serviceName,
            _productPrice,
            totalPoints
        );

        return true; // Indicates that the function was executed successfully
    }

    function setBaseReward(uint _initValue) public returns (bool) {
        baseReward = _initValue;

        return true; // Indicates that the function was executed successfully
    }

    // -- Actions - END

    // -- CRUD Operations - START
    function createUser(string memory _name) public returns (bool) {
        // Check if user already exists
        require(users[msg.sender].id == 0, "User already exists");
        require(
            !areEqual(users[msg.sender].name, _name),
            "UserName already exists"
        );

        // 1. Intialize the new user by accessing the "users" mapping
        User storage newUser = users[msg.sender];

        // 2. Intialize the new user's properties
        newUser.id = numUsers;
        newUser.totalPoints = 0;
        newUser.wallet = msg.sender;
        newUser.name = _name;

        emit UserCreation(numUsers, msg.sender, _name); // Emitting the corresponding Event

        // 2. Increament the "numUsers" so that we know:
        //   - How many users exist
        //   - Generate their IDs
        numUsers += 1;

        return true; // Indicates that the function was executed successfully
    }

    function createService(string memory _serviceName) public returns (bool) {
        Service storage newService = services[_serviceName];

        require(bytes(newService.name).length == 0, "Service already exists");

        newService.id = numServices;
        newService.totalEvents = 0;
        newService.name = _serviceName;

        emit ServiceCreation(numServices, _serviceName);

        numServices += 1;

        return true; // Indicates that the function was executed successfully
    }

    function createServiceInternal(
        string memory _serviceName
    ) private returns (bool) {
        Service storage newService = services[_serviceName];

        require(bytes(newService.name).length == 0, "Service already exists");

        newService.id = numServices;
        newService.totalEvents = 0;
        newService.name = _serviceName;

        numServices += 1;

        return true; // Indicates that the function was executed successfully
    }

    // Ex. eventCreator('CommentSubmission', 1, 1)
    function createEvent(
        string memory _eventName,
        string memory _serviceName,
        uint64 _multiplier
    ) public returns (bool) {
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];

        require(bytes(current_event.name).length == 0, "Event already exists");

        /**F
            uint id;
            uint totalPoints;
            string memory name;
            uint64 rewardMulti;
        */
        uint eventId = current_service.totalEvents;

        current_event.id = eventId;
        current_event.totalPoints = 0;
        current_event.name = _eventName;
        current_event.rewardMulti = _multiplier;

        emit EventCreation(eventId, _eventName, _serviceName);

        current_service.totalEvents += 1;

        return true; // Indicates that the function was executed successfully
    }

    // Ex. eventCreator('CommentSubmission', 1, 1)
    function createEventInternal(
        string memory _eventName,
        string memory _serviceName,
        uint64 _multiplier
    ) public returns (bool) {
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];

        require(bytes(current_event.name).length == 0, "Event already exists");

        /**
            uint id;
            uint totalPoints;
            string memory name;
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

    // -- Getter Functions - START
    function viewEvent(
        string memory _serviceName,
        string memory _eventName
    ) public view returns (ServiceEvent memory) {
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

    // -- Utility Functions - START
    function pointsCalc(uint _multiplier) public view returns (uint) {
        return baseReward * _multiplier;
    }

    // This should be in the Solidity's std library...
    // @dev Checks if 2 strings are equal. Returns true or false.
    // @notice If you want to check if a string is set or not,
    function areEqual(
        string memory string_1,
        string memory string_2
    ) internal pure returns (bool) {
        require(
            bytes(string_1).length >= 0 && bytes(string_2).length >= 0,
            "From: areEqual, probably inserted only one argument, two are required"
        );
        return
            keccak256(abi.encodePacked(string_1)) ==
            keccak256(abi.encodePacked(string_2));
    }

    // -- Utility Functions - END
}
