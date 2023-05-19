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
        uint id; // This is the id from the Game Contract
        address owner;
        uint price;
    }

    struct User {
        uint id;
        Card[] marketplace;
    }
    
    mapping(address => User) private users;
    // This mapping is gonna be used to diplay the Cards in the frontend!
    mapping(uint => Card) private cards; // *nn (ID used for this contract -NOT Game Contract- => Card)

    function createUser(address _wallet) public returns (uint) {
        if(users[_wallet].id != address(0)) return users[_wallet].id;
        users[_wallet].id = nextUserId;
        // The marketplace array will be automatically created and will be empty
        nextUserId++;
    }

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
        
         // Find the specific Card from the Player's marketplace
         for(uint i = 0; i < currentUser.inventory.length; i += 1) {
            // When you find it...
            if (currentUser.marketplace == _cardId) {
                // remove the Card from Player's Inventory & Marketplace
                // *This way is super bad practice as it comsumes a lot of gas, but the blockchain will be ours so... :)
                removeElementFromArray(i, currentUser.marketplace);
            }
        }
    }

    // This will be called from the Game Contract
    function putCardForSale(address _user, uint _cardId, uint _price) external {
        require(_user != address(0) && _cardId > 0 && _price > 0, "Wrong input while trying to sell the card");
        
        // Get the User struct (or obj) from the mapping users
        User storage currentUser = users[_user];
        
        // Add/Register new Card to Marketplace, by assigning it to the cards mapping
        cards[nextCardId] = Card({
            id: _cardId,
            owner: _user,
            price: _price
        });

        // This is done for us to be able to display in the frontend
        // the cards that the user has put for sale
        currentUser.marketplace.push(nextCardId);
    }


    function buyCard(address _buyer, uint _cardId) external {
        Card storage currentCard = cards[_cardId]; // This id is this contract's indentifier
        uint buyerGold = getGold(_buyer); // See below
        require(buyerGold >= currentCard.price, "Can not afford the Card");
        cardExchange(_buyer, currentCard.owner, currentCard.price, currentCard.id); // See below
        removeCard(currentCard.owner, _cardId);
    }

/*
    function getGold(address _user) returns uint gold {
        // Call a function from the Game Contract to get how much gold the user has
    }
*/

/*
    function cardExchange(address _buyer, address _seller, uint _amount, uint _cardId) returns uint gold {
        // Call a function from the Game Contract to reduce the buyer's gold, increase seller's gold by the _amount 
        // and finally change ownership of the card
    }
*/

}