// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
// import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// mapping(key => value) <access specifier> <name>;

contract SmartRPA is ERC721, ChainlinkClient {

    enum OfferResponse{ NO_RESPONSE, ACCEPT, REJECT }
    enum ClauseCode { INITIAL_RESPONSE, CLOSE_OF_ESCROW }

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
    
    constructor(address _link) ERC721("SmartRPA", "SRPA") public {
        buyer = msg.sender;
        seller = 0x479A603C1Cb5F019c50A90Eb74F046B89AB780f7;
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        jobId = "982105d690504c5d9ce374d040c08654";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
       
        activeOffer = false;
        offerRespondedTo = false;
    }

    // store url to RPA url (Docusign, etc...)
    function storeContract(string memory url) public activeRPA buyerOrSeller {
        rpa = url;
    }

    // display url to RPA url (Docusign, etc...)
    function retrieveContract() public view activeRPA returns (string memory) {
        return rpa;
    }
   
    // delete contract
    function terminateContract() public buyerOrSeller {
        selfdestruct(buyer);  
    }
    
    
    // dont call this function until some initial link has been deposited
    // activates the rpa (send initial offer to seller)
    // expire the rpa after expirationTime has elapsed (in minutes)
    function submitOffer(uint daysToRespond, string memory _rpa, address _oracle) public returns (bytes32 requestId) {
        require(msg.sender == buyer);
        activeOffer = true;
        offerRespondedTo = false;
        rpa = _rpa;
        // oracle = //0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b; // https://ethereum.stackexchange.com/q/96531/69999
        oracle = _oracle; // use dependency injection so we can pass mock oracles in for testing
        return createTimerForExpiration(daysToRespond * 1 minutes, "0"); // convert to minutes for timer (1440 minutes = 1 day), clauseCode ('0' = initial offer acceptance)
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
    function checkClause(uint256 _clauseCode) public view activeRPA buyerOrSeller returns (bool) {
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

    // check if the smart contract exists
    // only used for testing purposes
    function contractExists() public view returns (bool) {
        address contractAddress = address(this);
        uint size;
        assembly {
            size := extcodesize(contractAddress)
        }
        return size > 0;
    }

    // contract must be active for these functions to run
    modifier activeRPA() {
        require(activeOffer, "RPA contract hasn't been activated");
        _;
    }

    // contract request must originate from buyer or seller
    modifier buyerOrSeller() {
        require((msg.sender == buyer) || (msg.sender == seller));
        _;
    }

}
