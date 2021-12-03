// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract Nifty {
    struct NewOrder{
        uint State; //represents id order is open for execution 1, cancelled 0 or completed 2
        address ExecutorAddress;//represents the address of the individual who posted the order
        uint Price; //price individual is willing to give or take for the order
        uint quantity_left; //quantity of stocks left to be sold or bought
    }

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
        Sell_orders.push(NewOrder(1,address(this),price_sent,quantity_sent));
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
            for(uint j=0; j<Buy_orders.length; i++)
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
            for(uint j=0; j<Sell_orders.length; i++)
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
//     // A function to post a buy order for underlying security, function will take all the 
//     // necesarry inputs to post a buy order as parameter and will return the status of order.
//     function buy() payable public returns(){
//         // check if the value of money sent matches with quantity*price
//         // place the order to array of buy orders
//         // check if any transaction is possible
//         // process all the possible transactions
//         // return if order was executed or not
//     }

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
