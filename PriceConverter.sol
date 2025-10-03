// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
//import directly from npm - https://www.npmjs.com/package/@chainlink/contracts
//This gives us the ABI that we need!
import {AggregatorV3Interface} from "@chainlink/contracts@1.4.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
//cannot have state variables, and all functions should be internal
library PriceConverter{

    //to get price of ethereum(wei) in terms of usd
    function getPrice() internal view returns(uint256){
        // Need to reach out to the contract which has the price
        // need address and ABI
        // to get adress - go to price feeds on chainlink -> eth sepolia testnet -> eth/usd contract address
        // ABI - the interface that we are importing
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        //price of eth in usd - will come without decimal places but there are usually 8 decimal places (can use getdecimal() to confirm
        // so there will be 8 extra zeros. but ethAmount comes with 18 decimal places since it comes in wei.
        //decimals dont exist in solidity and so to make multiplication division work properly, lets multiply the usd value with 1e10
        return uint256(answer*1e10);
    }

    //coverts the eth amount passed to its value in usd
    function getConversionRate(uint256 ethAmount) internal view returns(uint256){
        uint256 ethPriceInUsd = getPrice(); //price of 1eth in usd value(*1e18)
        uint ethAmountInUsd = (ethPriceInUsd*ethAmount)/1e18; // divide by 1e18 because eth value is in wei which has 18 extra zeros
        //now here is why its imp that multipled answer with 10^10 - because eth could be less than 1 eth too, so the wei value might not
        //have 18 zeros..and if usd value also has only 8 zeros then we might end up with denominator>numerator
        // decimal values dont exist..so return value would end up being 0. 
        // we have to divide by 1e18 because its a given that eth will be in wei. After the above multiplication of the answer in usd
        //with 1e10, atleast we are assured that there will be 18 zeros in the numerator 
        //(usd value always comes with 8 trailing zeros so we dont need to worry about the usd value being less than 8 zeros in decimal place either
        //in solidity, always do multiplication before division!!
        return ethAmountInUsd; //this is gonna be usdamt*10^18
    }
}