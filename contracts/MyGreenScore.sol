// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyGreenScore is ERC20, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() ERC20("MyGreenScore", "MGS") {
        _setupRole(OWNER_ROLE, msg.sender);
        // _setupRole(MANAGER_ROLE, address(this));

        _mint(address(this), 1000000 * (10 ** uint256(decimals()))); // This is how much the contract gets
        _mint(msg.sender, 500 * (10 ** uint256(decimals()))); // This is the MGS Token that the Deployer gets
    }

    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, msg.sender),
            "MyGreenScore: caller is not the owner"
        );
        _;
    }

    function loadUpRewardingTool(address _addr) public onlyOwner {
        _mint(_addr, 2000000 * (10 ** uint256(decimals()))); // This is how much the Rewarding contract gets
    }

    function loadUpThisContract() public onlyOwner {
        _mint(address(this), 1000000 * (10 ** uint256(decimals())));
    }

    function mintAndTransferMGS(uint _amount, address _to) public onlyOwner {
        _mint(_to, _amount * (10 ** uint256(decimals()))); // This is how much the Rewarding contract gets
    }

    // Function to assign Manager access level category
    function assignManagerRole(address account) public onlyOwner {
        grantRole(MANAGER_ROLE, account);
    }

    // Function to assign Custom access level category
    function assignRole(bytes32 _rule, address _account) public onlyOwner {
        grantRole(_rule, _account);
    }

    // Function to create new Access level categoryies
    function setupRole(bytes32 _rule, address _account) public onlyOwner {
        _setupRole(_rule, _account);
    }
}