// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

// Import ERC-1155
// These imports only work with Remix IDE
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameManager is ERC1155, Ownable { // (GENERA) Address: 0xdceAE859c3590A5E91688FFb166ec5708f1c2d99

    // Reminder of ERC-1155 structure: 
    // (address => uint       => uint)
    // (player  => Token Type => Amount)
    // (john_23 => Card       =>  1)

    struct Player {
        uint id; // Contract ID
        uint server_id; // Server ID
        string name; // Player Name
    }
    
    struct Card {
        uint nft_id; // NFT's ID
        uint card_id; // Card ID on the Server (ideally would be the same with the NFT ID)
        uint template_id; // Card's Type ID -> (For example: 1 => Wind Turbine)
        bool inMP; // a flag that represents if the card is placed in Marketplace for sale
        address owner;
    }

    mapping(address => Player) public players;
    // NFT ID => Card Instance
    mapping(uint256 => Card) public cardsNFT;
    // Server ID => Card Instance
    mapping(uint256 => Card) public cardsServer;

    /**
    * This mapping hold the unique NFT IDs that a Player possesses.
    * When used with ERC-1155's "balanceOf()" it can return all the Cards and their amounts
    * But in our case all Cards are NFTs so the amount is always (1)
    * If we wish to obtain more information about each of those NFTs, we simply use the
    * cards mapping to find the corresponding Card Instance
    */
    //     (Player => [12, 435, 6552])
    mapping(address => uint256[]) private ownedTokens;

    uint public numPlayers;
    uint public numCards;
    address public contractAddress;

    constructor() ERC1155("https://game.example/api/card/{id}.json") {
        // The one deploying becomes the contract's owner
        contractAddress = address(this);
    }

    /**
    * @dev Runs when a new Player is created
    * @param _name The Player's in-game name
    */
    function createPlayer(string calldata _name, uint _server_id) public {
        require(bytes(_name).length == 0, "Player already exists, (From: _name)");
        require(_server_id >= 0, "Invalid Server ID, (From: _server_id)");

        players[msg.sender] = Player(numPlayers, _server_id, _name); // Creates a new Player instance
        numPlayers++;
    }

    /**
    * @dev Runs when a new Card is created
    * @param _card_id The Card's ID on the Server
    * @param _template_id The Card's Template ID, is used to get Card's properties and Metadata
    * @param _inMP A flag indicating if the Card is for on the Marketplace
    */
    function createCard(uint _card_id, uint _template_id, bool _inMP) public {
        require(cardsServer[_card_id].nft_id == 0, "Card already exists");
        require(_template_id > 0 && _template_id < 100, "Parameter: _template_id, is invalid");

        Card memory _currentCard = Card(numCards, _card_id, _template_id, _inMP, msg.sender); // Creates a Card instance
        cardsNFT[numCards] = _currentCard;
        _mint(msg.sender, numCards, 1, ""); // Creates the NFT, the "Amount" (3rd arg) = 1, because is an NFT
        numCards++;

        cardsServer[_card_id] = _currentCard;
        ownedTokens[msg.sender].push(_currentCard.nft_id);
    }

    /**
    * @dev Allows an admin to mint a NFT for a player
    * @param _to The Player's address
    */
    function mintForPlayer(address _to /* uint amount */) public {
        _mint(_to, numCards, 1 /* amount */, "");
        numCards++;
    }

    /**
    * @dev Transfers a Card Instance and the representing NFT when an exchange is performed in the Marketplace
    * @param _seller The Seller's address
    * @param _buyer The Buyer's address
    * @param _cardId The Card's Server-side ID
    */
    function transferCard(address _seller, address _buyer, uint _cardId /*, uint _amount*/ ) public {
        require(msg.sender != _seller, "The Seller can not start this transaction");
        require(_buyer != _seller, "The Seller and Buyer can not be the some person");

        Card storage card = cardsServer[_cardId]; // Get the Card using its Server ID (we need the NFT's ID)
        safeTransferFrom(_seller, _buyer, card.nft_id, 1, "0x0"); // handles the ERC-1155 NFT transfer magic
        
        uint256[] storage _sellerCards = ownedTokens[_seller]; // Get Seller's Cards
        card.owner = _buyer; // Change the owner (In my records, not ERC-1155's)

        // Find the card.nft_id and remove it from the _sellerCards array of the `_seller` address
        for (uint i = 0; i < _sellerCards.length; i++) {
            if (_sellerCards[i] == card.nft_id) {
                // This is the token to delete; swap it with the last one
                _sellerCards[i] = _sellerCards[_sellerCards.length - 1];
                break;
            }
         }

        // And now remove the last array element, which is the NFT in question
        _sellerCards.pop();
        
        // And add the NFT to the new owner's array
        ownedTokens[_buyer].push(card.nft_id);


    }

    /**
    * @dev Executes when a Card is put on sale on the Marketplace
    * @dev Its purpose is to update the Contract State in case there is a need for this info in the future
    * @param _card_id The Seller's address
    */
    function changeMP_status(uint _card_id) public {
        Card storage card = cardsServer[_card_id]; // Get the Card using its Server ID (we need the NFT's ID)
        require(card.nft_id != 0, "The Card does not exist");
        require(card.inMP == false, "The Card is already in the Marketplace");
        card.inMP = true;

    }

    /**
    * @dev Retrieves all Caller's NFTs
    */
    function getOwnedTokens() public view returns (uint256[] memory) {
        return ownedTokens[msg.sender];

    }

    /**
    * @dev Retrieves a specific Player's NFTspp
    * @param _owner The Seller's address
    */
    function getOwnedTokens(address _owner) public view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }

    /**
    * @dev Returns the Card's Owner's Address
    * @param _card_id The Server-Side Card ID
    */
    function getCardOwner(uint _card_id) public view returns (address) {
        return cardsServer[_card_id].owner;
    }
}
