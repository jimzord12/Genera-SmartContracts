// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MyToken is ERC1155 {
    
    constructor(address _ownerAddr) ERC1155("https://my-token-metadata.com/{id}.json")  {
        // Here, you would initialize any variables or mappings that you need for your token
        contractOwner = _ownerAddr;
        contractAddr = address(this);
    }

    address contractOwner;
    address contractAddr;

    uint public nextUserId = 1;
    uint public nextCardId = 1;

    struct Card {
        uint id;
        uint cardTemplateId;
        address owner;
        uint price;
        bool state; // On Market (for sale) = true | Off Market = false
    }

    struct User {
        uint id;
        // uint totalCardsInMP;
        // Card[] inventory;
        Card[] marketplace;
    }
    
    mapping(address => User) private users;
    mapping(uint => Card) private cards;

/* These come fromt the Template ChatGPT-3 gave me...
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        _mint(account, id, amount, data);
    }
    
    function burn(address account, uint256 id, uint256 amount) public {
        _burn(account, id, amount);
    }
*/
    // Step #1 Create a User, if does not already exist
    function createUser(address _wallet) public returns (uint) {
        if(users[_wallet].id != address(0)) return users[_wallet].id;
        users[_wallet].id = nextUserId;
        // The inventory & marketplace will be automatically created and will be empty
        nextUserId++;
    }

    // Step #2 Get Player's Cards from the Game's Smart Contract
    function getUserCards(address _user) public returns (Card[] memory)  {
        User storage currentUser = users[_user];
        Card[] memory retrievedCards; // Call a function from the Game Contract to get all the user's cards
        
        // Adds the retrieved cards to Player's Inventory
        for(uint i = 0; i < retrievedCards.length; i += 1) {
            currentUser.inventory.push(retrievedCards[i]);
        }
    }

    // function addCardToUser(address _user, uint _cardId) public {
    //     require(cards[_cardId].id > 0, "Card not found");
    //     User storage currentUser = users[_user];
    //     currentUser.inventory.push(cards[_cardId]);
    // }

    // Utility function, removes a specific element from an specific array
    function removeElementFromArray(uint _index, Card[] memory _array ) public {
        require(_index < _array.length, "Index out of range");

        // Shift all the elements after the index down by one
        for (uint i = _index; i < _array.length - 1; i++) {
            _array[i] = _array[i+1];
        }

        // Remove the last element of the array
        _array.pop();
    }

    function removeCard(address _user, uint _cardId) private {
        // Get the specific User from the mapping (kinda like a mini Database that why we need the "storage" keyword) 
        User storage currentUser = users[_user];
        
        // Create a temporary (memory) variable of type "Card"
        Card memory currentCard; // This might have to be "storage" and not "memory", don't remember :/

         // Find the specific Card from the Player's Inventory
         for(uint i = 0; i < currentUser.inventory.length; i += 1) {
            // When you find it...
            if (currentUser.inventory[i].id == _cardId) {

                // Assign the Card to variable for cleaner code
                currentCard = currentUser.inventory[i];
                // Check if the Card was for sale
                require(currentCard.state == true, "Can not a Card that is not for Sale");
                // remove the Card from Player's Inventory & Marketplace
                // *This way is super bad practice as it comsumes a lot of gas, but the blockchain will be ours so... :)
                removeElementFromArray(i, currentUser.inventory);
                removeElementFromArray(i, currentUser.marketplace);
            }
        }
    }

    // 
    function putCardForSale(uint _user, uint _cardId, uint _price) public /* OnlyService */ {
        require(_user != address(0) && _cardId > 0 && _price > 0, "Wrong input while trying to sell the card");
        User storage currentUser = users[_user];
        Card memory currentCard; // This might have to be "storage" and not "memory", don't remember :/

        // Find the specific Card from the Player's Inventory
        for(uint i = 0; i < currentUser.inventory.length; i += 1) {
            // When you find it...
            if (currentUser.inventory[i].id == _cardId) {

                // Assign the Card to variable for cleaner code
                currentCard = currentUser.inventory[i];
                // Change the the Card's state to: "for sale"
                currentCard.state = true;
                // Insert the price tag
                currentCard.price = _price;
                // Add it to Player's Marketplace
                currentUser.marketplace.push(currentCard);
            }
        }
    }

    function buyCard(address _user, uint _cardId) external {
        Card storage currentCard = cards[_cardId];
        uint userGold = getGold(_user); // Not yet implemented, See below
        require(userGold >= currentCard.price, "Can not afford the Card");
        cardExchange(_user, currentCard.owner, currentCard.price, currentCard.id); // Not yet implemented, See below
    }

/*
    function getGold(address _user) returns uint gold {
        // Call a function from the Game Contract to get how much the user has 
    }
*/

/*
    function cardExchange(address _buyer, address _seller, uint _amount, uint _cardId) returns uint gold {
        // Call a function from the Game Contract to reduce the buyer's gold, increase seller's gold by the _amount 
        // and finally change ownership of the card
    }
*/








}