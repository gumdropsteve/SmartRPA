// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SmartRPA is ERC721, Ownable, ChainlinkClient {

    address payable private buyer;
    address payable private seller;
   
    string rpa;
   
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
   
    bool private finalFundsDeposited;
    bool public underContract;
    
    string clauseCode;

    mapping(string => uint) clauseCodes;
    mapping(string => uint) offerResponses;
    
    struct Offer {
        uint256 initialResponseTime;  // in days
        uint256 closeOfEscrowTime;  // in days
        string rpaURL;  // url to contract on docusign or etc...
        bool activeOffer;
        bool offerRespondedTo; // have the offer been responded to?
        uint256 offerResponse; // what's the offer response code?
        bytes32 requestid;
        }
    Offer[] public offers;

    mapping(bytes32 => string) requestToRPA;
    mapping(bytes32 => address) requestToSender;
    mapping(uint256 => string) requestToTokenId;
    mapping(address => address payable) addressToPayable;

    constructor(address _link) 
    ERC721("SmartRPA", "SRPA") 
    public {
        buyer = msg.sender;
        seller = msg.sender;

        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);}

        jobId = "982105d690504c5d9ce374d040c08654";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b; // https://ethereum.stackexchange.com/q/96531/69999
        
        clauseCodes['INITIAL_RESPONSE'] = 0;
        clauseCodes['CLOSE_OF_ESCROW'] = 1;

        offerResponses['ACCEPT'] = 0;
        offerResponses['COUNTER'] = 1;
        offerResponses['REJECT'] = 2;
        offerResponses['NORESPONSE'] = 999;
    }

    // store url to RPA url (Docusign, etc...)
    function storeContract(string memory url) public buyerOrSeller {
        rpa = url;
    }

    // display url to RPA url (Docusign, etc...)
    function retrieveContract() public view returns (string memory) {
        return rpa;
    }

    // offer no longer on the table
    // transfers ownership of SRPA token to nobody
    function burn(uint256 tokenId)
    public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }

    // dont call this function until some initial link has been deposited
    // activates the rpa (send initial offer to seller)
    // expire the rpa after expirationTime has elapsed (in minutes)
    function submitOffer(uint256 daysToRespond, string memory _rpa) public returns (bytes32 requestId) {
        uint256 newId = offers.length; // token id
        requestId = createTimerForExpiration(daysToRespond * 1 minutes,
                                             newId,
                                             "INITIAL_RESPONSE"); // convert to minutes for timer (1440 minutes = 1 day), clauseCode ('0' = initial offer acceptance)
        requestToRPA[requestId] = _rpa;
        requestToSender[requestId] = msg.sender;
        offers.push(Offer(daysToRespond, // add offer to collection
                          daysToRespond + 30, // close of escrow
                          _rpa, // contract url
                          true, // active offer?
                          false, // offer responded to?
                          999, // offer response (999=none)
                          requestId // chainlink request id
                          ));
        _safeMint(requestToSender[requestId], newId); // create offer token
        return requestId;
    }
    
    /**
     * Create a Chainlink request to start a timer
     * when the timer expires, the rpa is considered expired
     */
    function createTimerForExpiration(uint256 durationInMinutes, uint256 _tokenID, string memory _clauseCode) 
    private returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, 
                                                                 address(this), 
                                                                 this.expireRPAContract.selector);
        request.addUint("until", block.timestamp + durationInMinutes);
        request.add("tokenId", requestToTokenId[_tokenID]);
        request.add("_clauseCode", _clauseCode);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * check contract condition to see if it's been met or not
     */
    function checkClause(uint256 tokenId, uint256 _clauseCode) public view returns (bool) {
        if(_clauseCode==0) {   // initial response
            if (offers[tokenId].offerRespondedTo==true) {
                return true;
            } else {
                return false;
            }
        } else if(_clauseCode==1) { // close of escrow
            if (finalFundsDeposited==true) {
                return true;
            } else {
                return false;
            }
        } else { // to do  // loan approval ... etc...
            if (underContract==true) {
                return true;
            } else {
                return false;
            }
        }       
    }

    // is an offer (token) active?
    function isActive(uint256 tokenId) public view returns (bool) {
        return offers[tokenId].activeOffer;
    }

    // how many offers have been submitted?
    function getNumberOfOffers() public view returns (uint256) {
        return offers.length; 
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * respond to offer
     * 0=accept, 1=counter, 2=reject
     */
    function respondToOffer(uint256 tokenId, uint256 responseCode) public {
        require(msg.sender == seller);
        offers[tokenId].offerRespondedTo = true;
        offers[tokenId].offerResponse = responseCode;
        if(responseCode==2) {   // if else statement
            offers[tokenId].activeOffer = false;
        } else {
            offers[tokenId].activeOffer = true;
            underContract = true;
            buyer = addressToPayable[ownerOf(tokenId)];
            }
        }

    /**
     * fires when the RPA contract is expired
     * should return the contract balance to the owners (buyer) address
     * and clears the contract data from the block chain
     */
    function expireRPAContract(bytes32 _requestId, uint256 _tokenID, string memory _clauseCode) 
    public recordChainlinkFulfillment(_requestId) {
        if (checkClause(_tokenID, clauseCodes[_clauseCode])==false) {
            burn(_tokenID);
        }
        else {
        }
    }

    // return details of offer token
    function getOfferDetails(uint256 tokenId) 
    public view
        returns (
        uint256 initialResponseTime,  // in days
        uint256 closeOfEscrowTime,  // in days
        string memory rpaURL,  // url to contract on docusign or etc...
        bool activeOffer,
        bool offerRespondedTo, // have the offer been responded to?
        uint256 offerResponse // what's the offer response code?
        )
    {
        return (
            offers[tokenId].initialResponseTime,
            offers[tokenId].closeOfEscrowTime,
            offers[tokenId].rpaURL,
            offers[tokenId].activeOffer,
            offers[tokenId].offerRespondedTo,
            offers[tokenId].offerResponse
        );
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

    // contract request must originate from buyer or seller
    modifier buyerOrSeller() {
        require((msg.sender == buyer) || (msg.sender == seller));
        _;
    }
}
