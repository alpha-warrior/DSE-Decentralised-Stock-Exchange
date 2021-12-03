// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract Nifty {
    struct NewOrder{
        uint order_id; // represents the order ID
        uint State; //represents id order is open for execution 1, cancelled 0 or completed 2
        address payable ExecutorAddress;//represents the address of the individual who posted the order
        uint Price; //price individual is willing to give or take for the order
        uint quantity_left; //quantity of stocks left to be sold or bought
    }

    uint number_of_orders; 
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
        Sell_orders.push(NewOrder(number_of_orders,1,address(this),price_sent,quantity_sent));
        number_of_orders++;
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
        require(msg.value == snet_price*sent_qty,"WRONG, amount of money paid"); // check if the value of money sent matches with quantity*price
        for(uint i=0;i<Sell_orders.length;i++)
        {
            if(Sell_orders[i].Price > sent_price)
            {
                break;
            }
            else
            {
                if(Sell_orders.qty_left <= sent_qty)
                {
                    uint temp_qty = Sell_orders.qty_left;
                    OwnedStocks[address(this)] -= temp_qty;
                    OwnedStocks[msg.sender] += temp_qty;
                    Sell_orders[i].ExecutorAddress.transfer(sent_price*temp_qty);
                    Sell_orders[i].qty_left -= temp_qty;
                    if(Sell_orders[i].qty_left == 0)
                    {
                        Sell_orders[i].State = 2;
                    }
                    sent_qty -= temp_qty;
                }
                else
                {
                    uint temp_qty = sent_qty;
                    OwnedStocks[address(this)] -= temp_qty;
                    OwnedStocks[msg.sender] += temp_qty;
                    Sell_orders[i].ExecutorAddress.transfer(sent_price*temp_qty);
                    Sell_orders[i].qty_left -= temp_qty;
                    if(Sell_orders[i].qty_left == 0)
                    {
                        Sell_orders[i].State = 2;
                    }
                    sent_qty -= temp_qty;
                }
            }
        }

        if(sent_qty !=0)
        {
            Buy_orders.push(NewOrder(number_of_orders,1,msg.sender,sent_price,sent_qty));
            number_of_orders++;
        }
        sort_Buy_orders();
        sort_Sell_orders();
    }

//     // A function to post a sell order for underlying security, function will take all the 
//     // necesarry inputs to post a sell order as parameter and will return the status of order.
//     function sell() payable public returns(){
//         // check if the adress posting order owns the quantity of security to be sold
//         // place the order to array of sell orders
//         // check if any transaction is possible
//         // process all the possible transactions
//         // return if order was executed or not
//     }    

//     // A function to cancel an order for underlying security, function will take all the 
//     // necesarry inputs to cancel an order as parameter.
//     function cancelOrder() public{
//         // check if person cancelling order is also the one who posted it
//         // check if order is not executed yet
//         // if order not executed cancel order
//     }

//     // A function to get state of order, functiont will take all the necessary inputs to 
//     // verify state of order like order id and will return state of order
//     function getOrderStatus() view public returns(string memory)
//     {
//         // check if person asking order status is also the one who posted it
//         // return string representing if order is executed, cancelled, open.
//     }

//     // A function to get last trading price of underlying security
//     function getMarketPrice() view public returns(uint)
//     {
//         // return last tranaction price of order
//     }

//     // A function to get the market depth of the underlying security
//     function getMarketDepth() view public returns(string)
//     {
//         // return market depth of underlying security
//     }
}
