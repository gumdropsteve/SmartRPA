// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract SmartRPA is ERC721, ChainlinkClient {
    address payable private owner;
    string rpa;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    bool public active;

    constructor() ERC721("SmartRPA", "SRPA") public {
        owner = msg.sender;
        
        setPublicChainlinkToken();
        oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
        jobId = "982105d690504c5d9ce374d040c08654";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        active = false;
    }

    // store url to RPA PDF (most basic implementation)
    function store(string memory url) public activeRPA {
        require(msg.sender == owner);
        rpa = url;
    }

    // display url to RPA PDF (most basic implementation)
    function retrieve() public view activeRPA returns (string memory){
        return rpa;
    }
    
    // delete contract
    function close() private { 
        require(msg.sender == owner);
        selfdestruct(owner); 
    }

    // dont call this function until some initial link has been deposited
    // activates the rpa
    // expire the rpa after expirationTime has elapsed (in minutes)
    function activateRPA(uint expirationTime) public {  
        active = true;  
        createTimerForExpiration(expirationTime); // in minutes
    }

    /**
     * Create a Chainlink request to start a timer
     * when the timer expires, the rpa is considered expired
     */
    function createTimerForExpiration(uint256 durationInMinutes) private activeRPA returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.expireRPAContract.selector);
        request.addUint("until", block.timestamp + durationInMinutes * 1 minutes);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * fires when the RPA contract is expired
     * should return the contract balance to the owners address
     * and cleares the contract data from the block chain
     */ 
    function expireRPAContract(bytes32 _requestId, uint256 _volume) public activeRPA recordChainlinkFulfillment(_requestId)
    {
        close();
    }

    modifier activeRPA() {
        require(active, "RPA contract hasn't been activated");
        _;
    }
}
