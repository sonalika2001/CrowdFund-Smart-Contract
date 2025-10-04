// Get funds from users - store the mapping
// Withdraw funds from contract and put in wallet
//Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

//import directly from npm - https://www.npmjs.com/package/@chainlink/contracts
//This gives us the ABI that we need!
import {AggregatorV3Interface} from "@chainlink/contracts@1.4.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner(); //this is outside the contract(so again gas cost not included in deployment), custom error declared here

contract FundMe {

    //to attach the functions in our PriceConverter library to all uint256 vars
    using PriceConverter for uint256; //this type should be the same as the type of param being passed to the functions
    //if anything is being passed^

    //anyone should be able to call this func - hence public
    //payable means this function can receive funds. Just like wallets can hold funds
    //contracts can hold funds too

    address[] public funders;
    mapping(address funder =>uint256 amountFunded) public addressToAmtFunded;

    //we need to make sure withdraw can only be called by the owner of this contract
    //so when it is deployed, we need to save the address of the account deploying it
    //hence, we need a constructor - this is immediately called whenever you deploy your contract
    //ie it is called in the exact same transaction which is used to deploy your contract
    address immutable i_owner;
    constructor(){
        i_owner = msg.sender; //address of the deployer of the contract

    }
    //value known at compile time and it wont change, hence constant. saves gas
    uint256 public constant MINIMUM_USD = 5e18; //since getconversionrate returns with 18 extra decimal places
    function fund() public payable{
        //Allow users to send money
        //set a min limit on the amount to be sent

        //can access the value of tokens sent with the message - using global called "msg.value"
        //msg.value is in wei
        //all such globals can be found in the solidity documentation

        //require is similar to minimum - it sets the min limit of value
        // 1e18 -> 1 ETH
        // if false, then 2nd param is logged
        //require(msg.value >1e18, "didn't send enough eth");
        
        //greater than > 5 usd
        //msg.value.getConversionRate() works because we have attached the library to all uint256
        require(msg.value.getConversionRate()>MINIMUM_USD, "didn't send enough eth");
        //if >5, then maintain list of funders
        funders.push(msg.sender); //msg.sender is a global variable that stores the address of the sender of the transaction
        addressToAmtFunded[msg.sender]+=msg.value;
    }

    function withdraw() public onlyOwner {
        //add a check if the caller of withdraw function is the owner
        // require(msg.sender==owner,"Only owner of the contract can withdraw.");
        //remove funds from the map to show that we have withdrawn
        for (uint256 funderIndex=0;funderIndex<funders.length;funderIndex++){
           address funder = funders[funderIndex];
           addressToAmtFunded[funder]=0; 
        }

        // reset the array 
        funders = new address[](0); //new keyword here is for resetting the array 

        //actually withdraw the funds
        // 3 ways
        //transfer - msg.sender is of address type, while payable msg.sender makes it payable address
        // payable(msg.sender).transfer(address(this).balance); // transfer all the balance at the address of this contract
        
        // //send - returns bool 
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Send failed");

        //recommended way
        //call - we need to pass fields and their values just like its a transaction info to call, and ("") is actually if we are calling
        //a specific function in some contract. here we arent so we leave it empty
        //it returns a bool and any data returned since we could be calling functions that return something
        //we are basically converting the address of the receiver of funds(msg.sender) to payable and adding the value inside curly brackets
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}("");
        //can leave dataReturned blank
        require(callSuccess, "Call failed");
        

    }
    
    // add this as func decorator to perform before/after the function operations are executed
    //we could also do _; and then require.. to execute the function code first and then the modifier stuff
    //useful if something needs to be checked in multiple funcs
    modifier onlyOwner {
        if (msg.sender!=i_owner){
            revert NotOwner(); //this saves a lot of gas compared to the commented out line, since we dont have to
            //store and emit the error string
        }
        // require(msg.sender==i_owner,"Only owner can access.");
        _; //this means that after executing the above line, execute everything else in the function now

    }   

    receive() external payable {
        fund();
    } 
    fallback() external payable {
        fund();
    }
}