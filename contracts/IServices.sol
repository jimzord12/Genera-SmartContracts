// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

interface IServices {
    function baseReward() external view returns (uint);

    function contractAddress() external view returns (address);

    function owner() external view returns (address);

    function numServices() external view returns (uint);

    function checkOwnerRole(address _account) external view returns (bool);

    function getEventMulti(
        string memory _serviceName,
        string memory _eventName
    ) external view returns (uint64);

    function createService(
        string calldata _serviceName
    ) external returns (bool);

    function createEvent(
        string calldata _eventName,
        string calldata _serviceName,
        uint64 _multiplier
    ) external returns (bool);

    function viewEvent(
        string calldata _serviceName,
        string calldata _eventName
    ) external view returns (ServiceEvent memory);

    function assignRole(bytes32 _rule, address _account) external;

    function setupRole(bytes32 _rule, address _account) external;

    struct ServiceEvent {
        uint id;
        uint totalPoints;
        string name;
        uint64 rewardMulti;
    }

    struct Service {
        uint id;
        string name;
        uint totalEvents;
        mapping(string => ServiceEvent) events;
    }

    event ServiceCreation(uint indexed id, string indexed name);
    event EventCreation(
        uint indexed id,
        string indexed name,
        string indexed serviceName
    );
}
