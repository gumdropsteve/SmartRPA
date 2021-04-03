// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
// import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// mapping(key => value) <access specifier> <name>;

contract SmartRPA is ERC721, ChainlinkClient {
    address payable private buyer;
    address payable private seller;
   
    string rpa;
   
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
   
    bool public activeOffer;
    bool public offerRespondedTo;
    bool private finalFundsDeposited;
    
    string clauseCode;
    
    constructor() ERC721("SmartRPA", "SRPA") public {
        buyer = msg.sender;
        seller = 0x479A603C1Cb5F019c50A90Eb74F046B89AB780f7;
        
        setPublicChainlinkToken();
        oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b; // https://ethereum.stackexchange.com/q/96531/69999
        jobId = "982105d690504c5d9ce374d040c08654";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
       
        activeOffer = false;
        offerRespondedTo = false;
    }

    // store url to RPA url (Docusign, etc...)
    function storeContract(string memory url) public activeRPA {
        require((msg.sender == buyer) || (msg.sender == seller));
        rpa = url;
    }

    // display url to RPA url (Docusign, etc...)
    function retrieveContract() public view activeRPA returns (string memory) {
        return rpa;
    }
   
    // delete contract
    function terminateContract() private {
        require((msg.sender == buyer) || (msg.sender == seller));
        if (activeOffer == false) {
            selfdestruct(buyer);
        } else {
            activeOffer = true;
        }    }
    
    // dont call this function until some initial link has been deposited
    // activates the rpa (send initial offer to seller)
    // expire the rpa after expirationTime has elapsed (in minutes)
    function submitOffer(uint daysToRespond, string memory _rpa) public {
        require(msg.sender == buyer);
        activeOffer = true;
        offerRespondedTo = false;
        rpa = _rpa;
        createTimerForExpiration(daysToRespond * 1 minutes, "0"); // convert to minutes for timer (1440 minutes = 1 day), clauseCode ('0' = initial offer acceptance)
    }

    /**
     * Create a Chainlink request to start a timer
     * when the timer expires, the rpa is considered expired
     */
    function createTimerForExpiration(uint256 durationInMinutes, string memory _clauseCode) private activeRPA returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.expireRPAContract.selector);
        request.addUint("until", block.timestamp + durationInMinutes);
        request.add("clauseCode", _clauseCode);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * check contract condition to see if it's been met or not
     */
    function checkClause(uint256 _clauseCode) public view activeRPA returns (bool) {
        require((msg.sender == buyer) || (msg.sender == seller));
        if(_clauseCode==0) {   // initial response
            if ((offerRespondedTo==true) && (activeOffer==true)) {
                return true;
            } else {
                return false;
            }
        } else if(_clauseCode==1) { // close of escrow
            if ((finalFundsDeposited==true) && (activeOffer==true)) {
                return true;
            } else {
                return false;
            }
        } else {  // loan approval ... etc...
            if (offerRespondedTo==true) {
                return true;
            } else {
                return false;
            }
        }       
    }
    
    /**
     * respond to offer
     * 0=accept, 1=counter, 2=reject
     */
    function respondToOffer(uint256 responseCode, string memory _rpa) public activeRPA {
        require(msg.sender == seller);
        offerRespondedTo = true;
        rpa = _rpa;
        if(responseCode==2) {   // if else statement
            activeOffer = false;
        } else {
            activeOffer = true;
            }
        }
   
    /**
     * fires when the RPA contract is expired
     * should return the contract balance to the owners (buyer) address
     * and clears the contract data from the block chain
     */
    function expireRPAContract(bytes32 _requestId, uint256 _clauseCode) public activeRPA recordChainlinkFulfillment(_requestId) {
        if (checkClause(_clauseCode)==false) {
            terminateContract();
        }
    }

    // contract must be active for these functions to run
    modifier activeRPA() {
        require(activeOffer, "RPA contract hasn't been activated");
        _;
    }

}
