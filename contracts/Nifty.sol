// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

// import "truffle/Console.sol";

contract Nifty {
    struct NewOrder{
        uint order_id; // represents the order ID
        uint State; //represents id order is open for execution 1, cancelled 0 or completed 2
        address payable ExecutorAddress;//represents the address of the individual who posted the order
        uint Price; //price individual is willing to give or take for the order
        uint qty_left; //quantity of stocks left to be sold or bought
    }

    uint number_of_orders; 
    uint marketprice;
    // number of orders placed 

    string private Symbol; 
    // string, denoting the name of the asset exchanged by the smart contract
    
    mapping (address=> uint) private OwnedStocks; 
    // A mapping to store the owner address and the quantity of the assets owned
    
    
    NewOrder[] private Sell_orders; 
    // NewOrder array, A sorted array of type NewOrder Structure of all the 
    // selling orders which are yet to be executed
    
    NewOrder[] private Buy_orders; 
    // NewOrder array, A sorted array of type NewOrder Structure of all the 
    // buying orders which are yet to be executed.


    NewOrder[] private temp_orders; 
    // NewOrder array, A temporary array of type NewOrder Structure 


    // constructor which provides options for IPO
    constructor(string memory symbol_sent, uint quantity_sent,uint price_sent) public
    {
        Symbol = symbol_sent;
        OwnedStocks[address(this)] = quantity_sent;
        Sell_orders.push(NewOrder(number_of_orders,1,address(uint160(address(this))),price_sent,quantity_sent));
        number_of_orders++;
        marketprice = price_sent;
    }


    // function to sort Buy_orders
    function sort_Buy_orders() internal 
    {
        // NewOrder[] storage temp_orders;
        temp_orders.length = 0;
        for(uint i=0; i<Buy_orders.length; i++)
        {
            uint found = 0;
            uint found_id = 0;
            for(uint j=0; j<Buy_orders.length; j++)
            {
                if(Buy_orders[j].State == 1)
                {
                    if(found==0)
                    {
                        found = 1;
                        found_id = j;
                    }
                    else
                    {
                        if(Buy_orders[found_id].Price < Buy_orders[j].Price)
                        {
                            found_id = j;
                        }
                    }
                }
            }
            if(found == 1)
            {
                temp_orders.push(Buy_orders[found_id]);
                Buy_orders[found_id].State = 0;
            }
        }

        Buy_orders.length = 0;

        for(uint i = 0 ; i<temp_orders.length ; i++)
        {
            Buy_orders.push(temp_orders[i]);
        }
        temp_orders.length = 0;
    }

    // function to sort Sell_orders
    function sort_Sell_orders() internal 
    {
        // NewOrder[] storage temp_orders;
        temp_orders.length = 0;
        for(uint i=0; i<Sell_orders.length; i++)
        {
            uint found = 0;
            uint found_id = 0;
            for(uint j=0; j<Sell_orders.length; j++)
            {
                if(Sell_orders[j].State == 1)
                {
                    if(found==0)
                    {
                        found = 1;
                        found_id = j;
                    }
                    else
                    {
                        if(Sell_orders[found_id].Price > Sell_orders[j].Price)
                        {
                            found_id = j;
                        }
                    }
                }
            }
            if(found == 1)
            {
                temp_orders.push(Sell_orders[found_id]);
                Sell_orders[found_id].State = 0;
            }
        }

        Sell_orders.length = 0;

        for(uint i = 0 ; i<temp_orders.length ; i++)
        {
            Sell_orders.push(temp_orders[i]);
        }
        temp_orders.length = 0;
    }   


    // A function to post a buy order for underlying security, function will take all the 
    // necesarry inputs to post a buy order as parameter and will return the status of order.
    function buy(uint sent_price, uint sent_qty) payable public
    {
        // string memory ret = "TEST";
        require(msg.value == sent_price*sent_qty,"WRONG, amount of money paid"); // check if the value of money sent matches with quantity*price
        for(uint i=0;i<Sell_orders.length;i++)
        {
            if(Sell_orders[i].Price > sent_price)
            {
                break;
            }
            else
            {
                if(Sell_orders[i].qty_left <= sent_qty)
                {
                    marketprice = sent_price;
                    uint temp_qty = Sell_orders[i].qty_left;
                    OwnedStocks[address(this)] -= temp_qty;
                    OwnedStocks[msg.sender] += temp_qty;
                    
                    if(Sell_orders[i].ExecutorAddress != address(uint160(address(this))) )
                    {
                    Sell_orders[i].ExecutorAddress.transfer(sent_price*temp_qty);
                    }

                    Sell_orders[i].qty_left -= temp_qty;
                    if(Sell_orders[i].qty_left == 0)
                    {
                        Sell_orders[i].State = 2;
                    }
                    sent_qty -= temp_qty;
                }
                else
                {
                    marketprice = sent_price;
                    uint temp_qty = sent_qty;
                    OwnedStocks[address(this)] -= temp_qty;
                    OwnedStocks[msg.sender] += temp_qty;
                    if(Sell_orders[i].ExecutorAddress != address(uint160(address(this))) )
                    {
                        Sell_orders[i].ExecutorAddress.transfer(sent_price*temp_qty);
                    }
                    Sell_orders[i].qty_left -= temp_qty;
                    if(Sell_orders[i].qty_left == 0)
                    {
                        Sell_orders[i].State = 2;
                    }
                    sent_qty -= temp_qty;
                }
            }
        }

        if(sent_qty > 0)
        {
            Buy_orders.push(NewOrder(number_of_orders,1,msg.sender,sent_price,sent_qty));
            number_of_orders++;
        }
        sort_Buy_orders();
        sort_Sell_orders();
    }


    function sell(uint sell_price, uint sell_qty) payable public
    {
        require(OwnedStocks[msg.sender] >= sell_qty, "You do not have enough shares to sell");
        
        for(uint i=0;i<Buy_orders.length;i++)
        {
            if(Buy_orders[i].Price < sell_price)
            {
                break;
            }
            else
            {
                if(Buy_orders[i].qty_left <= sell_qty)
                {
                    marketprice = Buy_orders[i].Price;
                    uint temp_qty = Buy_orders[i].qty_left;
                    OwnedStocks[Buy_orders[i].ExecutorAddress] += temp_qty;
                    OwnedStocks[msg.sender] -= temp_qty;
                    address(uint160(msg.sender)).transfer(Buy_orders[i].Price*temp_qty);
                    Buy_orders[i].qty_left -= temp_qty;
                    if(Buy_orders[i].qty_left == 0)
                    {
                        Buy_orders[i].State = 2;
                    }
                    sell_qty -= temp_qty;
                }
                else
                {
                    marketprice = Buy_orders[i].Price;
                    uint temp_qty = sell_qty;
                    OwnedStocks[Buy_orders[i].ExecutorAddress] += temp_qty;
                    OwnedStocks[msg.sender] -= temp_qty;
                    address(uint160(msg.sender)).transfer(Buy_orders[i].Price*temp_qty);
                    Buy_orders[i].qty_left -= temp_qty;
                    if(Buy_orders[i].qty_left == 0)
                    {
                        Buy_orders[i].State = 2;
                    }
                    sell_qty -= temp_qty;
                }
            }
        }

        if(sell_qty !=0)
        {
            Sell_orders.push(NewOrder(number_of_orders,1,msg.sender,sell_price,sell_qty));
            OwnedStocks[msg.sender] -= sell_qty;
            OwnedStocks[address(this)] += sell_qty;
            number_of_orders++;
        }
        sort_Buy_orders();
        sort_Sell_orders();
    }

    function getDetails(uint orderid) public view returns(string memory)
    {

        string memory ret = "";

        uint found = 0;

        for(uint i=0;i<Buy_orders.length;i++)
        {
            if(found == 0)
            {
            if(Buy_orders[i].order_id == orderid)
            {
                require(Buy_orders[i].ExecutorAddress == msg.sender, "You are not the owner of this Buy order");
                ret = string(abi.encodePacked(ret,"\n*****************","\n","Order ID: ",uint2str(Buy_orders[i].order_id),"\n",
                "Price: ",uint2str(Buy_orders[i].Price),"\n",
                "Quantity left: ", uint2str(Buy_orders[i].qty_left),"\n",
                "State: ",uint2str(Buy_orders[i].State),"\n"));
                
                found = 1;
                break;
            }
            }
        }

        for(uint i=0;i<Sell_orders.length;i++)
        {
            if(found == 0)
            {
            if(Sell_orders[i].order_id == orderid)
            {
                require(Sell_orders[i].ExecutorAddress == address(uint160(msg.sender)), "You are not the owner of this Sell order");
                
                ret = string(abi.encodePacked(ret,"\n*****************","\n","Order ID: ",uint2str(Sell_orders[i].order_id),"\n",
                "Price: ",uint2str(Sell_orders[i].Price),"\n",
                "Quantity left: ", uint2str(Sell_orders[i].qty_left),"\n",
                "State: ",uint2str(Sell_orders[i].State),"\n"));
                
                found = 1;
                break;

            }
            }
        }

        if(found == 0)
        {
            ret = string("This Order ID you have provided does not exist, or the order is cancelled or fully executed");
        }
        return ret;
    }

    function getMarketPrice() public view returns(string memory)
    {
        string memory ret = "";
        ret = string(abi.encodePacked(ret,"\n*****************","\n","Market Price: ",uint2str(marketprice),"\n"));
        return ret;
    }

    function getMarketDepth() public view returns(string memory)
    {
        string memory ret = "";
        uint length = 0;
        ret = string(abi.encodePacked(ret, "\n**********SELL ORDERS*********\n"));
        if(Sell_orders.length <=5)
        {
            length = Sell_orders.length;         
        }
        else
        {
            length = 5;
        }
        for(uint i=0;i<length;i++)
        {
            if(Sell_orders[i].State == 1)
            {
                ret = string(abi.encodePacked(ret, "\nx) Price: ", uint2str(Sell_orders[i].Price), "-> Shares: ", uint2str(Sell_orders[i].qty_left)));
            }
        }
        ret = string(abi.encodePacked(ret, "\n\n**********BUY ORDERS*********\n"));
        if(Buy_orders.length <=5)
        {
            length = Buy_orders.length;         
        }
        else
        {
            length = 5;
        }
        for(uint i=0;i<length;i++)
        {
            if(Buy_orders[i].State == 1)
            {
                ret = string(abi.encodePacked(ret, "\nx) Price: ", uint2str(Buy_orders[i].Price), "-> Shares: ", uint2str(Buy_orders[i].qty_left)));
            }
        }
        return ret;
    }

    function cancel_buyorder(uint orderid) public payable
    {
        uint found = 0;
        for(uint i=0;i<Buy_orders.length;i++)
        {
            if(Buy_orders[i].order_id == orderid)
            {
                require(Buy_orders[i].ExecutorAddress == address(uint160(msg.sender)), "You are not the owner of this Buy order");
                require(Buy_orders[i].State == 1, "The Order is already cancelled or fulfilled");
                Buy_orders[i].ExecutorAddress.transfer(Buy_orders[i].Price*Buy_orders[i].qty_left);
                Buy_orders[i].State = 0;
                found = 1;
                break;

            }
        }
        require(found == 1,"This Order ID you have provided does not exist, please recheck");
        sort_Buy_orders();
    }

    function cancel_sellorder(uint orderid) public 
    {
        uint found = 0;
        for(uint i=0;i<Sell_orders.length;i++)
        {
            if(Sell_orders[i].order_id == orderid)
            {
                require(Sell_orders[i].ExecutorAddress == msg.sender, "You are not the owner of this Sell order");
                require(Sell_orders[i].State == 1, "The Order is already cancelled or fulfilled");
                Sell_orders[i].State = 0;
                OwnedStocks[msg.sender] += Sell_orders[i].qty_left;
                OwnedStocks[address(this)] -= Sell_orders[i].qty_left;
                found = 1;
                break;

            }
        }
        require(found == 1,"This Order ID you have provided does not exist, please recheck");
        sort_Sell_orders();
    }

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
}