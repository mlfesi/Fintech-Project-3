//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleAuction{
    //parameters of the SimpleAuction
    address payable public beneficiary; 
    uint public auctionEndTime;

    //Current state of the auctionEndTime
    address public highestBidder;
    uint public highestBid;

    //Keep track of what address has bid how much and has been outbid and waiting for initial bid amount to be returned
    mapping(address => uint) public pendingReturns;

    //Track if auction has ended
    bool ended = false;

    //Keep track of highest bid and amount
    event HighestBidIncrease(address bidder, uint amount);
    //keep track of winner and amount of auctions
    event AuctionEnded(address winner, uint amount); 

    constructor(uint _biddingTime, address payable _beneficiary){
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid()public payable{
        if (block.timestamp > auctionEndTime){
            revert("The auction has ended");
        }

        if (msg.value <= highestBid){
            revert("There is a higher or equal bid");
        }

        if (highestBid != 0){
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncrease(msg.sender, msg.value);
    }

    function withdraw()public returns(bool){
        uint amount = pendingReturns[msg.sender];
        if (amount >0){
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        if(block.timestamp < auctionEndTime){
            revert ("The auction is open");
        }
        if (ended){
            revert("The function auctionEnded has already been called");
        }

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}