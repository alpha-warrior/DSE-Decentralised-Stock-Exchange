// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract Netflix {
    struct Item{
        uint listing_id; /** Stores the listing id, which is equal to the number of listed products till date at the time of listing */
        string name; /** Stores the name of the listed product */
        string description; /** Stores the desctiption of the listed product */
        uint price; /** Stores the price of the listed product */
        uint seller_id; /** Stores the seller_id of the listed product */
        uint bought; /** Stores if the product has been bought yet. O for No, 1 for Yes */
        uint delivered; /** Stores if the bought product has been delivered yet. O for No, 1 for Yes */
        uint buyer_id; /** Stores the buyer_id if the product has been bought*/
        string buyer_public_key; /** Stores the public key of the buyer if the product has been bought */
        string encrypted_msg; /** Stores the cipher text encrypted by the Seller using the Buyer's public key if the product has been bought */
    }

    uint private sellers = 0; /**  Stores the number of sellers. This also acts as a key for the reverse mapping of sellers*/
    uint private buyers = 0; /**  Stores the number of buyers. This also acts as a key for the reverse mapping of buyers*/
    uint private listed_items = 0; /**  Stores the number of listed items created till date. This also acts as a unique identifier for newly created listed items*/

    mapping (uint => address) private buyers_mapping; /**  This mapping maps a buyer_id (proxy for value of "buyers" when the buyer first bought a product) to the address of the buyer's account*/
    mapping (uint => address payable) private sellers_mapping; /**  This mapping maps a seller_id (proxy for value of "sellers" when the seller first listed a product) to the address of the seller's account*/

    mapping (address => uint) private reverse_buyers_mapping; /** This reverse mapping maps the address of a buyer's account to its buyer_id */
    mapping (address => uint) private reverse_sellers_mapping; /** This reverse mapping maps the address of a seller's account to its seller_id */

    Item[] private listedItems; /** This is a dynamic array of the listed items storing all the information about each item (represented as a struct) */

    /**
     * This internal pure function takes as input a uint_256 unsigned 256 integer and converts it to a string.
     * @param _i The integer to be converted to string
     * @return The string created from the input integer
     */

    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    /**
     * This public function is called by the Seller and takes as input the name, description and price of an item and adds it to the list for all the Buyers to see.
     * @param _name The name of product being listed
     * @param _description The description of product being listed
     * @param _price The price of product being listed
     */

    function listItem(string memory _name, string memory _description, uint _price) public
    {
        if(reverse_sellers_mapping[msg.sender]==0)
        {
            sellers++;
            reverse_sellers_mapping[msg.sender] = sellers;
            sellers_mapping[sellers] = address(uint160(msg.sender));
            listedItems.push(Item(listed_items,_name,_description,_price,sellers,0,0,0,"NA","NA"));
            listed_items++;
        }
        else
        {
            uint temp_seller_id = reverse_sellers_mapping[msg.sender];
            listedItems.push(Item(listed_items,_name,_description,_price,temp_seller_id,0,0,0,"NA","NA"));
            listed_items++;
        }
    }

    /**
     * This public view function lists all the items currently listed along with Listing ID, Name, Description and Price
     * @return The list is returned
     */

    function viewAvailItems() public view returns(string memory)
    {
        string memory ret = "";
        uint counter= 0;
        for (uint i=0; i < listedItems.length; i+=1) 
        {
            Item memory cur = listedItems[i];
            if (cur.bought == 0)
            {
                counter++;
                ret = string(abi.encodePacked(ret,"\n\n","**************************","\n","Listing Id: ",uint2str(cur.listing_id),"\n","Name: ",cur.name,"\n","Description: ",cur.description,"\n","Price: ",uint2str(cur.price)));
            }
        }
        if(counter!=0)
        {
            ret = string(abi.encodePacked(ret,"\n","***************************"));
        }
        else 
        {
            ret = "NO NETFLIX SCREENS ARE CURRENTLY UP FOR SALE";
        }
        return ret;
    }

    /**
     * This public payable function is called by a potential Buyer when he wants to buy a specific listed product.
     * The buyer also gives the price of the prouct in the msg.value while calling which should exactly match with the listed price for a succesful transaction.
     * The function transfers money (stages it) from the Buyer's account to the Contract's address.
     * @param listing_id The listing id of the product the buyer is interested in buying.
     * @param _public_key The public key of the buyer which will then be encrypted by the seller and then decrupted later by the buyer
     */

    function buyItem(uint listing_id,string memory _public_key) public payable
    {
        require(msg.value==listedItems[listing_id].price,"Wrong amount paid. Please pay the correct amount to claim your item.");
        if(reverse_buyers_mapping[msg.sender]==0)
        {
            buyers++;
            reverse_buyers_mapping[msg.sender] = buyers;
            buyers_mapping[buyers] = msg.sender;
            listedItems[listing_id].bought = 1;
            listedItems[listing_id].buyer_public_key = _public_key;
            listedItems[listing_id].buyer_id = buyers;
        }
        else
        {
            listedItems[listing_id].bought = 1;
            listedItems[listing_id].buyer_public_key = _public_key;
            listedItems[listing_id].buyer_id = reverse_buyers_mapping[msg.sender];
        }
    }

    /**
     * This public view function is called by the Seller of the listed product which was just bought to retrieve the public key of the Buyer to encrypt Password with.
     * @param listing_id The listing id of the product the buyer just bought.
     * @return The public key of the buyer
     */

    function get_public_key(uint listing_id) public view returns(string memory)
    {
        require(reverse_sellers_mapping[msg.sender]!=0,"You are not a seller");
        require(listedItems[listing_id].seller_id==reverse_sellers_mapping[msg.sender],"Item is not listed by you");
        require(listedItems[listing_id].bought==1,"Item not bought yet");
        string memory ret = listedItems[listing_id].buyer_public_key;
        
        return ret;
    }

    /**
     * This public payable function is called by the Seller of the listed product.
     * This function takes in the cipher text created by the Seller and then transfers the Price of the product from the Contract's address to the Seller.
     * @param message The encrypted cipher text created using the sensitive message and Buyer's public key.
     * @param listing_id The listing id of the product the buyer just bought.
     */

    function send_encrypted_string(string memory message,uint listing_id) public payable
    {
        require(reverse_sellers_mapping[msg.sender]!=0,"You are not a seller");
        require(listedItems[listing_id].seller_id==reverse_sellers_mapping[msg.sender],"Item is not listed by you");
        require(listedItems[listing_id].bought==1,"Item not bought yet");
        listedItems[listing_id].encrypted_msg = message;
        listedItems[listing_id].delivered = 1;
        sellers_mapping[listedItems[listing_id].seller_id].transfer(listedItems[listing_id].price);
    } 

    /**
     * This public view function is called by the Buyer of the listed product.
     * This function returns the cipher text to the Buyer.
     * @param listing_id The listing id of the product the buyer just bought.
     * @return The cipher text created by the Seller.
     */

    function get_encrypted_string(uint listing_id) public view returns(string memory)
    {
        require(reverse_buyers_mapping[msg.sender]!=0,"You are not a Buyer");
        require(listedItems[listing_id].buyer_id==reverse_buyers_mapping[msg.sender],"Item is not bought by you");
        require(listedItems[listing_id].bought==1,"Item not bought yet");
        require(listedItems[listing_id].delivered==1,"Item not delivered yet");
        string memory ret = listedItems[listing_id].encrypted_msg;
        return ret;
    }
}
