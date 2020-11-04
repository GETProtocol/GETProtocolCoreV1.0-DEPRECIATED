pragma solidity ^0.6.0;

import "./ERC721_CLEAN.sol";
import "./Pausable.sol";
import "./MinterRole.sol";
import "./RelayerRole.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MetaDataTE.sol";
 
abstract contract ERC721_TICKETING_V2 is ERC721_CLEAN, Pausable, MinterRole, RelayerRole, Ownable, MetaDataTE  {

    constructor (string memory name, string memory symbol) public ERC721_CLEAN(name, symbol) {}

    using Counters for Counters.Counter;
    Counters.Counter private _nftIndexs;

    mapping(uint256 => bool) public _nftScanned; 
    mapping (uint256 => address) private _ticketIssuerAddresses;  
    mapping (uint256 => address) private _eventAddresses;

    address public event_metadata_TE_address;
    address public ticket_metadata_address;

    event txPrimaryMint(address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txScan(address originAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);

    /** 
     * @dev Set event_metadata_TE_address for NFT Factory contract (used to store metadata of events and ticketIssuer - TE)
     */ 
    function updateMetadataTEAddress(address _new_metadata_TE) public onlyOwner {
        event_metadata_TE_address = _new_metadata_TE;
    }

    /** 
     * @dev Set ticket_metadata_address for NFT Factory contract (used to store metadata of tickets)
     */ 
    function updateMetadataTicketAddress(address new_ticket_metadata) public onlyOwner {
        ticket_metadata_address = new_ticket_metadata;
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) public override onlyRelayer returns(bool success) {
        return MetaDataTE(event_metadata_address).newTicketIssuer(ticketIssuerAddress, ticketIssuerName, ticketIssuerUrl);
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) public override returns(bool success) {
        return MetaDataTE(event_metadata_address).newEvent(eventAddress, eventName, shopUrl, coordinates, startingTime, tickeerAddress);
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function getEventDataAll(address eventAddress) public override view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketIssuerName, address, string memory ticketIssuerUrl) {
        return MetaDataTE(event_metadata_address).getEventDataAll(eventAddress);
    }


    /**  onlyRelayer - caller needs to be whitelisted relayer
    * @notice In the first transaction the ticketMetadata is stored in the metadata of the NFT.
    * @param destinationAddress addres of the to-be owner of the NFT 
    * @param ticketMetadata string containing the metadata about the ticket the NFT is representing
    * @param ticketMetadata XX 
    */
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata) public onlyMinter returns (uint256) {

        /// Fetches nftIndex and autoincrements it
        _nftIndexs.increment();
        uint256 nftIndex = _nftIndexs.current();
        
        _mint(destinationAddress, nftIndex);
        
        // Storing the address of the ticketIssuer in the NFT
        _markTicketIssuerAddress(nftIndex, ticketIssuerAddress);
        _markEventAddress(nftIndex, eventAddress);
        
        /// Storing the ticketMetadata in the NFT        
        _setnftMetadata(nftIndex, ticketMetadata);
        
        // Set scanned state to false (unscanned)
        bool statusNft;
        statusNft = false;
        _setnftScannedBool(nftIndex, statusNft);
        
        // Fetch blocktime as to assist ticket explorer for ordering
        uint _timestamp;
        _timestamp = block.timestamp;
        emit txPrimaryMint(destinationAddress, ticketIssuerAddress, nftIndex, _timestamp);
        
        return nftIndex;
    }


    /** 
    * @notice This function can only be called by a whitelisted relayer address (onlyRelayer).
    * @notice The nftIndex will be fetched by the contract using ownerOf(originAddress)
    * @param originAddress address of the current owner of the getNFT
    * @param destinationAddress addres of the to-be owner of the NFT 
    */
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer {

        // In order to move an getNFT the 
        uint256 nftIndex;

        // A getNFT can only have 1 NFT per address, so this function will always fetch 
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        // TODO -> TX needs to throw if originAddress does not own an getNFT.

        /// Verify if originAddress is owner of nftIndex
        require(ownerOf(nftIndex) == originAddress, "GET TX FAILED Func:secondaryTransfer - transfer of nftIndexx that is not owned by owner");
        
        /// Verify if the destinationAddress isn't burn-address
        require(destinationAddress != address(0), "GET TX FAILED Func:secondaryTransfer -  transfer to the zero address");
        
        /// Transfer the NFT to destinationAddress
        _relayerTransferFrom(originAddress, destinationAddress, nftIndex);
        
        // Capture time of tx for the ticketexplorer
        uint _timestamp;
        _timestamp = block.timestamp;

        /// Emit event of secondary transfer
        emit txSecondary(originAddress, destinationAddress, getAddressOfTicketIssuer(nftIndex), nftIndex, _timestamp);
    }

    /** onlyRelayer - caller needs to be whitelisted relayer
    * @notice Returns the NFT of the ticketIssuer back to its address + cleans the ticketMetadata from the NFT 
    * @notice Function doesn't require autorization/sig of the NFT owner!
    * @dev Only a whitelisted relayer address is able to call this contract (onlyRelayer).
    */
    function scanNFT(address originAddress) public onlyRelayer {

        uint256 nftIndex; 
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        address destinationAddress = getAddressOfTicketIssuer(nftIndex);

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
     * @dev Internal function that stores the _ticketIssuerAddress in the NFT metadata.
     * @notice For minting the destinationAddress is always a ticketIssuerAddress 
     */ 
    function _markTicketIssuerAddress(uint256 nftIndex, address _ticketIssuerAddress) internal {
        require(_exists(nftIndex), "GET TX FAILED Func: _markTicketIssuerAddress : Nonexistent nftIndex");
        _ticketIssuerAddresses[nftIndex] = _ticketIssuerAddress;
    }

    /** 
     * @dev TODO 
     * @notice TODO
     */ 
    function _markEventAddress(uint256 nftIndex, address _eventAddress) internal {
        require(_exists(nftIndex), "GET TX FAILED Func: _markEventAddress : Nonexistent nftIndex");
        _eventAddresses[nftIndex] = _eventAddress;
    }

    /**
    * @dev Returns the address of the ticketIssuerAddress that controls the NFT
     */
    function getAddressOfTicketIssuer(uint256 nftIndex) public view returns (address) {
        require(_exists(nftIndex), "GET TX FAILED Func: getAddressOfTicketIssuer : Nonexistent nftIndex");
        return _ticketIssuerAddresses[nftIndex];
    }

    /**
    * @dev Returns the Eventaddress of the getNFT
     */
    function getEventAddress(uint256 nftIndex) public view returns (address) {
        require(_exists(nftIndex), "GET TX FAILED Func: getEventAddress : Nonexistent nftIndex");
        return _eventAddresses[nftIndex];
    }

    /**
    * @dev Sets a getNFT metadata value to true/false.
    * @notice Will fail if nftScannedBool is already scanned. 
    * TODO 
     */
    function _setnftScannedBool (uint256 nftIndex, bool status) internal {
        require(_exists(nftIndex), "GET TX FAILED Func: _setnftScannedBool: Nonexistent nftIndex");
        require(_nftScanned[nftIndex] != true, "GET TX FAILED Func: _setnftScannedBool: NFT already in scanned state.");
        _nftScanned[nftIndex] = status;
    }    

}