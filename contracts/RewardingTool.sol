// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IOracle.sol"; // Importing the Oracle's Interface

contract RewardingTool is AccessControl {
    // Contract Address (GENERA - Network): 0x300302fEc3D905eb66Cb7743C636F8741B72dB3a
    // using SafeERC20 for IERC20;

    // -- Global Score - START
    uint public baseReward;
    IERC20 private token; // This contract is our ERC-20 MGS Tokens
    IOracle private oracle; // This contract provides randomness
    address public contractAddress;
    address public owner;
    // address public erc20_addr;

    mapping(address => User) public users;
    mapping(string => address) public userNames;
    mapping(string => Service) public services;
    mapping(uint => Product) public products;

    uint public numUsers;
    uint public numServices;
    uint public numProducts;
    uint public numPendingProds;

    // bytes32 public constant DEFAULT_ADMIN_ROLE =
    //     keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // -- Global Score- END

    constructor(IERC20 _token, /*address _tokenAddress,*/ IOracle _oracle) {
        baseReward = 10; // Applying a default value
        contractAddress = address(this);
        // erc20_addr = _tokenAddress;
        owner = msg.sender;
        token = _token;
        oracle = _oracle;

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

        // Creating some Products
        Product[4] memory testProducts;

        // Defining some Products
        Product memory ingameGold = createProduct(
            10,
            1,
            "ToGameGoldConversion",
            "N/A",
            false,
            true,
            false
        );
        Product memory coffee = createProduct(
            25,
            30,
            "Coffee",
            "Paros",
            false,
            false,
            false
        );
        Product memory ticket = createProduct(
            50,
            15,
            "Ticket",
            "Sifnos",
            false,
            false,
            true
        ); // This should not be visible to the user from the UI
        Product memory meal = createProduct(
            70,
            1,
            "Meal",
            "Mykonos",
            false,
            false,
            false
        ); // This should get disabled once it someone claims it!

        // Manual Array Elements Assignments
        testProducts[0] = ingameGold;
        testProducts[1] = coffee;
        testProducts[2] = ticket;
        testProducts[3] = meal;

        for (uint i = 0; i < testProducts.length; i++) {
            products[i] = testProducts[i];
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

    event ProductCreation(
        string indexed name,
        uint indexed price,
        uint indexed amount,
        string location
    ); //TODO: Test this!

    event ProductAquired(uint indexed id, string indexed name); //TODO: Test this!

    event ProductClaimed(
        uint indexed id,
        string indexed name,
        uint indexed price
    ); //TODO: Test this!

    // -- Events Section - END

    // -- Structs Section - START

    struct Product {
        // Ex. It can be a physical, real or digital redeemable reward (brelock, in-game currency, free musceum tickets
        uint id;
        uint price;
        uint32 amount; // MAX_VALUE uint32, dec: 4,294,967,295 || hex: 0xFFFFFFFF
        bool isEmpty;
        bool isInfinite;
        bool isDisabled;
        string name;
        string location;
    }

    struct PendingProduct {
        uint id;
        uint productId;
        bytes32 collectionHash; // keccak256(username + productId + 6-digit nonce)
        bool isRedeemed;
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
    //       addPoints(             ,                      forum,  comment                 )
    function addPoints(
        string memory _serviceName,
        string memory _eventName
    ) public returns (bool) {
        User storage current_user = users[msg.sender];
        Service storage current_service = services[_serviceName]; // Get the Service from payload
        ServiceEvent storage current_event = current_service.events[_eventName]; // Get the Event from the Service and payload

        // 1. Find out how much points to give | Calc Reward
        uint reward = pointsCalc(current_event.rewardMulti);

        // 2. Increase User's Total Points
        token.transfer(msg.sender, reward);
        // token.safeTransferFrom(msg.sender, contractAddress, reward);
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
        token.transfer(msg.sender, _reward);
        // current_user.totalPoints += _reward;

        // 2. Increase User's Service Points (For Statistic Reasons)
        current_user.pointsPerService[_serviceName] += _reward;

        // 3. Store the points conserning the specific Service & Event (For Statistic Reasons)
        current_event.totalPoints += _reward;

        emit PointsGained(_to, _reward); // Emits the relevant event

        return true; // Indicates that the function was executed successfully
    }

    function productClaimer(uint _productId) external {
        // -1. >Frontend: Before, calling this function! Call Oracle and give it a random number, we need it for later.

        // 0. >Frontend: Make user complete an Auth Signing Challenge
        // require(
        //     _productId >= 0,
        //     "This product does not exist! You propably made a typo :)"
        // );

        // 1. Use sender's address to find the user
        User storage current_user = users[msg.sender];

        require(
            bytes(current_user.name).length > 0,
            "You (the Tx sender), do not have an account, create one first."
        );

        // 2. Use _productId to find the corresponding product
        Product storage particular_product = products[_productId];

        // 3. Check if user can buy the Product
        require(
            token.balanceOf(msg.sender) >= particular_product.price,
            "User can not afford this Product!"
        );

        // 4. >Frontend: Ask the user to approve this contract to transfer the required tokens on his/her behalf.
        /*
            Example Code:
            // Create a new instance of the contract
            const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, signer);

            const amountToApprove = ethers.utils.parseUnits('10.0', 18); // Change the amount as needed, '18' is the typical number of decimal places for ERC-20 tokens

            // Call the approve function
            const approvalTx = await tokenContract.approve(spenderAddress, amountToApprove);

            // Wait for it to be mined
            setIsLoading(true); // For React Users
            await approvalTx.wait();
            console.log('Tokens approved');
        */

        // 5. If user can buy the Product and allows the contract to transfer token on his/her behalf, transfer the required amount of tokens (particular_product.price) from his/her account to the ERC-20 Contract.

        token.transferFrom(msg.sender, address(this), particular_product.price);

        // 6. Generate an 6-digit Nonce in order to create a "collectionHash"
        uint32 randomNonce = oracle.randomNumber();

        // 7. Craete the "collectionHash"
        bytes32 _collectionHash = hashValues(
            current_user.name,
            particular_product.id,
            randomNonce
        );

        // 8. Create the PendingProduct object
        PendingProduct memory pendingProd = PendingProduct(
            numPendingProds,
            particular_product.id,
            _collectionHash,
            false
        );

        numPendingProds += 1;

        // 9. Store it to the User's pendingProducts array
        current_user.pendingProducts.push(pendingProd);

        // 10. Subtract the particular Product's amount by 1, if it is not Infinite
        if (!particular_product.isInfinite) {
            uint32 temp_amount = particular_product.amount;
            require(
                !particular_product.isEmpty,
                "The specific Reward is out of Stock! Sorry!"
            );
            temp_amount -= 1;
            if (temp_amount == 0) setProdToEmpty(particular_product.id, true);
        }

        emit ProductClaimed(
            particular_product.id,
            current_user.name,
            particular_product.price
        );

        // 11. Finally, the random nonce will be sent to the UI (by Express server)so that the User can store it.
        // He/She will need this code to obtain the reward! Tell the user to write it down.
    }

    /**
     * Future: Also add the product to the Event
     */
    /*
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
*/

    // Met to be used by the personal who give out the Product/Rewards
    function redeemerValidator(
        string memory _name,
        uint32 _nonce,
        uint _id
    ) public managerLevel {
        require(bytes(_name).length > 0, "Username is required");
        require(_nonce > 0, "The Nonce can not be zero");

        // 1. We need to check if the function was executed successfully
        bool result = false;

        // 2. Finds the User's address using his/her username
        address user_address = userNames[_name];

        // 3. Finds the User Object using his/her address
        User storage current_user = users[user_address];

        // 4. Gets the User's Pending Products
        PendingProduct[] storage pendingProducts = current_user.pendingProducts;

        // 5. Gets the length of the Pending Products array, to use it in a loop
        uint pendingProdsLen = pendingProducts.length;

        // 6. We loop through the Pending Products to find the one we desire (this choice is made by the Fronted)
        for (uint16 i = 0; i < pendingProdsLen; i += 1) {
            if (pendingProducts[i].id == _id) {
                // 1. Hashed the args to calculate the "CollectionHash"
                bytes32 calculatedHash = hashValues(
                    _name,
                    pendingProducts[i].productId,
                    _nonce
                );
                if (pendingProducts[i].collectionHash == calculatedHash) {
                    pendingProducts[i].isRedeemed = true;
                    result = true;
                }
            }
        }

        require(
            result == true,
            "Something went wrong, No Reward or Wrong Input Data."
        );

        emit ProductAquired(_id, _name);
    }

    function setBaseReward(uint _initValue) public onlyOwner returns (bool) {
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
        userNames[_name] = msg.sender;

        // 2. Intialize the new user's properties
        newUser.id = numUsers;
        // newUser.totalPoints = 0;
        newUser.walletAddr = msg.sender;
        newUser.name = _name;

        emit UserCreation(numUsers, msg.sender, _name); // Emitting the corresponding Event

        // 2. Increament the "numUsers" so that we know:
        //   - How many users exist
        //   - Generate their IDs
        numUsers += 1;

        return true; // Indicates that the function was executed successfully
    }

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

    // Product Related Fucntions
    function createProduct(
        uint _price,
        uint32 _amount,
        string memory _name,
        string memory _location,
        bool _isEmpty,
        bool _isInfinite,
        bool _isDisabled
    ) public managerLevel returns (Product memory prod) {
        require(_price > 0, "Price must be greater than 0");
        require(_amount > 0, "Amount must be greater than 0");
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_location).length > 0, "Location is required");

        Product storage particular_product = products[numProducts];

        particular_product.id = numProducts;
        particular_product.price = _price;
        particular_product.amount = _amount;
        particular_product.name = _name;
        particular_product.location = _location;
        particular_product.isEmpty = _isEmpty;
        particular_product.isInfinite = _isInfinite;
        particular_product.isDisabled = _isDisabled;

        prod = particular_product;

        emit ProductCreation(_name, _price, _amount, _location);

        numProducts += 1;
    }

    function updateProdPrice(uint _id, uint _price) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        require(_price > 0, "Price must be greater than 0");
        Product storage particular_product = products[_id];
        particular_product.price = _price;
    }

    function updateProdAmount(uint _id, uint32 _amount) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        require(_amount > 0, "Amount must be greater than 0");
        Product storage particular_product = products[_id];
        particular_product.amount = _amount;
    }

    function updateProdName(uint _id, string memory _name) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        require(bytes(_name).length > 0, "Name is required");
        Product storage particular_product = products[_id];
        particular_product.name = _name;
    }

    function updateProdLocation(
        uint _id,
        string memory _location
    ) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        require(bytes(_location).length > 0, "Location is required");
        Product storage particular_product = products[_id];
        particular_product.location = _location;
    }

    function setProdToEmpty(uint _id, bool _option) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        Product storage particular_product = products[_id];
        particular_product.isEmpty = _option;
    }

    function setProdToInf(uint _id, bool _option) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        Product storage particular_product = products[_id];
        particular_product.isInfinite = _option;
    }

    function setDisableProduct(uint _id, bool _option) public managerLevel {
        require(
            _id > 0 && products[_id].id != 0,
            "This product does not exist! You propably made a typo :)"
        );
        Product storage particular_product = products[_id];
        particular_product.isDisabled = _option;
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
        // User storage current_user = users[_userAddr]; // Getting the requested user by using his/her wallet address
        return token.balanceOf(_userAddr);
    }

    function viewYourPoints() public view returns (uint) {
        // User storage you = users[msg.sender]; // Getting the requested user by using his/her wallet address
        return token.balanceOf(msg.sender);
    }

    function viewYourUnclaimedProds()
        public
        view
        returns (PendingProduct[] memory)
    {
        User storage you = users[msg.sender]; // Getting the requested user by using his/her wallet address
        return you.pendingProducts;
    }

    function getUserProducts(
        string memory _userName
    ) public view returns (PendingProduct[] memory userPendingProducts) {
        address currentUserAddr = userNames[_userName];
        User storage currentUser = users[currentUserAddr];
        require(
            bytes(_userName).length > 0,
            "getUserProducts: Invalid/Wrong Input"
        );
        require(
            bytes(currentUser.name).length > 0,
            "getUserProducts: User does not exist"
        );

        return currentUser.pendingProducts;
    }

    function getUserProducts(
        address _userAddr
    ) public view returns (PendingProduct[] memory userPendingProducts) {
        User storage currentUser = users[_userAddr]; // Getting the requested user by
        require(
            bytes(currentUser.name).length > 0,
            "getUserProducts: User does not exist"
        );

        return currentUser.pendingProducts;
    }

    // -- Getter Functions - END

    // -- AccessControl Functions - START

    // Function to assign Manager access level category
    function assignManagerRole(address _account) public onlyOwner {
        grantRole(MANAGER_ROLE, _account);
    }

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

    function hashValues(
        string memory name,
        uint256 productId,
        uint nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, productId, nonce));
    }

    // -- Utility Functions - END
    function checkOwnerRole(address _account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }
}
