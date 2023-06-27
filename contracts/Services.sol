// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract Services is AccessControl {
    // Contract Address (GENERA - Network): 0x300302fEc3D905eb66Cb7743C636F8741B72dB3a

    // -- Global Score - START
    uint public baseReward;
    address public contractAddress;
    address public owner;
    // address public erc20_addr;

    mapping(string => Service) public services;

    uint public numServices;

    // bytes32 public constant DEFAULT_ADMIN_ROLE =
    //     keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // -- Global Score- END

    constructor() {
        baseReward = 10; // Applying a default value
        contractAddress = address(this);
        // erc20_addr = _tokenAddress;
        owner = msg.sender;

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MANAGER_ROLE, address(this));

        // Just some automations cuz the contract is still under dev
        // Creating Services and ServiceEvents
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

    event ServiceCreation(uint indexed id, string indexed name); // OK

    event EventCreation(
        uint indexed id,
        string indexed name,
        string indexed serviceName
    ); // Ok

    // -- Events Section - END

    // -- Structs Section - START

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

    // -- Modifiers Section - START

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "RewardingTool.sol: caller is not the Owner"
        );
        _;
    }

    modifier managerLevel() {
        require(
            hasRole(MANAGER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "RewardingTool.sol: caller is not a Manager or the Owner"
        );
        _;
    }

    // -- Modifiers Section - END

    // -- Actions - START

    // -- Actions - END

    // -- CRUD Operations - START

    function createService(
        string memory _serviceName
    ) public managerLevel returns (bool) {
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
    ) private managerLevel returns (bool) {
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
    ) public managerLevel returns (bool) {
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
    ) public managerLevel returns (bool) {
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

    function getEventMulti(
        string memory _serviceName,
        string memory _eventName
    ) public view returns (uint64) {
        Service storage current_service = services[_serviceName];
        ServiceEvent storage current_event = current_service.events[_eventName];
        return current_event.rewardMulti;
    }

    // -- Getter Functions - END

    // -- AccessControl Functions - START

    // Function to assign Manager access level category

    // Function to assign Custom access level category
    function assignRole(bytes32 _rule, address _account) public onlyOwner {
        grantRole(_rule, _account);
    }

    // Function to create new Access level categoryies
    function setupRole(bytes32 _rule, address _account) public onlyOwner {
        _setupRole(_rule, _account);
    }

    // -- AccessControl Functions - END

    // -- Utility Functions - START
    function pointsCalc(uint _multiplier) internal view returns (uint) {
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
    function checkOwnerRole(address _account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }
}
