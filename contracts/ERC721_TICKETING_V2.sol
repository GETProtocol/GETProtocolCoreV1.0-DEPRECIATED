pragma solidity ^0.6.0;

import "./ERC721_CLEAN.sol";
import "./Pausable.sol";
import "./MinterRole.sol";
import "./RelayerRole.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MetaDataTE.sol";
 
abstract contract ERC721_TICKETING_V2 is ERC721_CLEAN, Pausable, MinterRole, RelayerRole, Ownable, MetaDataManager  {

    constructor (string memory name, string memory symbol) public ERC721_CLEAN(name, symbol) {}

    using Counters for Counters.Counter;
    Counters.Counter private _nftIndexs;

    // Optional mapping for token URIs
    mapping(uint256 => bool) public _nftScanned; 
    mapping (uint256 => address) private _ticketeerAddresss;  

    // address of the contract storing event & ticketeer metadata
    address public event_metadata_address;
    address public ticket_metadata_address;
    address public roles_metadata_address;

    function updateMetadataManagerContract(address _new_metadata) public onlyOwner {
        event_metadata_address = _new_metadata;
    }

    /** 
     * @dev Register address of ticketeer
     * @notice Data will be used for the getNFT ticket explorer. 
     */ 
    function newTicketeer(address ticketeerAddress, string memory ticketeerName, string memory ticketeerUrl) public override onlyRelayer returns(bool success) {
        return MetaDataTE(event_metadata_address).newTicketeer(ticketeerAddress, ticketeerName, ticketeerUrl);
    }

    function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) public override returns(bool success) {
        return MetaDataTE(event_metadata_address).newEvent(eventAddress, eventName, shopUrl, coordinates, startingTime, tickeerAddress);
    }

    function getEventDataAll(address eventAddress) public override view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketeerName, address, string memory ticketeerUrl) {
        return MetaDataTE(event_metadata_address).getEventDataAll(eventAddress);
    }

    event txPrimaryMint(address indexed destinationAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp);
    event txScan(address originAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp);

    /**  onlyRelayer - caller needs to be whitelisted relayer
    * @notice In the first transaction the ticketMetadata is stored in the metadata of the NFT.
    * @param destinationAddress addres of the to-be owner of the NFT 
    * @param ticketMetadata string containing the metadata about the ticket the NFT is representing
    */
    function primaryMint(address destinationAddress, address ticketeerAddress, string memory ticketMetadata) public onlyMinter returns (uint256) {

        /// Checks internal count of nftIndex and increments the count with 1
        _nftIndexs.increment();
        uint256 nftIndex = _nftIndexs.current();
        
        _mint(destinationAddress, nftIndex);
        
        // Storing the address of the ticketeer in the NFT
        _markTicketeerAddress(nftIndex, ticketeerAddress);
        
        /// Storing the ticketMetadata in the NFT        
        _setnftMetadata(nftIndex, ticketMetadata);
        
        bool statusNft;
        statusNft = false;
        
         // Set scanned state to false 
        _setnftScannedBool(nftIndex, statusNft);
        
        uint _timestamp;
        _timestamp = block.timestamp;

        /// Emit event of successful token mint
        // emit txMint(destinationAddress, nftIndex, _timestamp);
        emit txPrimaryMint(destinationAddress, ticketeerAddress, nftIndex, _timestamp);
        
        return nftIndex;
    }


    /** onlyRelayer - caller needs to be whitelisted relayer
    * @notice This function can only be called by a whitelisted relayer address (onlyRelayer).
    * @notice As tx is relayed msg.sender is assumed to be signed by originAddress.
    * @dev Tx will fail/throw if originAddress is not owner of nftIndex
    * @dev Tx will fail/throw if destinationAddress is genensis address.
    * @param destinationAddress addres of the to-be owner of the NFT 
    */
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer {

        uint256 nftIndex;
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        /// Verify if originAddress is owner of nftIndex
        require(ownerOf(nftIndex) == originAddress, "ERC721: transfer of token that is not owned by owner");
        
        /// Verify if destinationAddress isn't burn-address
        require(destinationAddress != address(0), "ERC721: transfer to the zero address");
        
        /// Transfer the NFT to destinationAddress
        _relayerTransferFrom(originAddress, destinationAddress, nftIndex);
        
        // Capture time of tx for the ticketexplorer
        uint _timestamp;
        _timestamp = block.timestamp;

        /// Emit event of successful tranffer
        emit txSecondary(originAddress, destinationAddress, getAddressOfTicketeer(nftIndex), nftIndex, _timestamp);
    }

    /** onlyRelayer - caller needs to be whitelisted relayer
    * @notice Returns the NFT of the ticketeer back to its address + cleans the ticketMetadata from the NFT 
    * @notice Function doesn't require autorization/sig of the NFT owner!
    * @dev Only a whitelisted relayer address is able to call this contract (onlyRelayer).
    */
    function scanNFT(address originAddress) public onlyRelayer {

        uint256 nftIndex; 
        // nftIndex = ownerOf(originAddress);
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        address destinationAddress = getAddressOfTicketeer(nftIndex);

        bool statusNft;
        statusNft = true;

        // Set scanned state to true 
        _setnftScannedBool(nftIndex, statusNft);
        
        // Capture time of tx for the ticketexplorer
        uint _timestamp;
        _timestamp = block.timestamp;
        
        emit txScan(originAddress, destinationAddress, nftIndex, _timestamp);
    }

    /** 
     * @dev Internal function that stores the _ticketeerAddress in the NFT metadata.
     * @notice For minting the destinationAddress is always a ticketeerAddress 
     */ 
    function _markTicketeerAddress(uint256 nftIndex, address _ticketeerAddress) internal {
        require(_exists(nftIndex), "ERC721Metadata: URI set of nonexistent token");
        _ticketeerAddresss[nftIndex] = _ticketeerAddress;
    }

    /**
    * @dev Returns the address of the ticketeerAddress that controls the NFT
    * @notice This address cannot be edited or changed.
     */
    function getAddressOfTicketeer(uint256 nftIndex) public view returns (address) {
        require(_exists(nftIndex), "ERC721Metadata: Tickeer owner query for nonexistent token");
        return _ticketeerAddresss[nftIndex];
    }

    function _setnftScannedBool (uint256 nftIndex, bool status) internal {
        require(_exists(nftIndex), "ERC721ScannedBool: Nonexistent nftIndex");
        require(_nftScanned[nftIndex] != true, "ERC721ScannedBool: Ticket was already scanned");
        _nftScanned[nftIndex] = status;
    }    

}