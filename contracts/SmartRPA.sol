// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract SmartRPA is ERC721, ChainlinkClient {
    address payable private owner;
    string rpa;

    bool public alarmDone;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor() ERC721("SmartRPA", "SRPA") public {
        owner = msg.sender;
        
        setPublicChainlinkToken();
        oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
        jobId = "982105d690504c5d9ce374d040c08654";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        alarmDone = false;

        // expire the rpa after 3 days
        this.createRPATimer(4320); // 4320 minutes = 3 days
    }

    // store url to RPA PDF (most basic implementation)
    function store(string memory url) public {
        require(msg.sender == owner);
        rpa = url;
    }

    // display url to RPA PDF (most basic implementation)
    function retrieve() public view returns (string memory){
        return rpa;
    }
    // delete contract
    function close() public { 
        require(msg.sender == owner);
        selfdestruct(owner); 
    }

    /**
     * Create a Chainlink request to start a timer
     */
    function createRPATimer(uint256 durationInMinutes) private returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.expireRPAContract.selector);
        request.addUint("until", block.timestamp + durationInMinutes * 1 minute);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * fires when the RPA contract is expired
     * should return the contract balance to the owners address
     * and self destruct the contract
     */ 
    function expireRPAContract(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        selfdestruct(owner); 
    }
}
