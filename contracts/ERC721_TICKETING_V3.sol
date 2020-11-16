pragma solidity ^0.6.0;

import "./ERC721_CLEAN.sol";
import "./Counters.sol";
import "./interfaces/IERCMetaDataIssuersEvents.sol";
import "./interfaces/IERCAccessControlGET.sol";
 
abstract contract ERC721_TICKETING_V3 is ERC721_CLEAN  {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    MetaDataIssuersEvents public METADATA_IE;
    AccessContractGET public BOUNCER;

    constructor (string memory name, string memory symbol) public ERC721_CLEAN(name, symbol) {
        BOUNCER = AccessContractGET(0xaC2D9016b846b09f441AbC2756b0895e529971CD);
        METADATA_IE = MetaDataIssuersEvents(0xF1cD6211CB0E6020eD3F888574f3bA964cf2fCd5);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _nftIndexs;

    mapping(uint256 => bool) public _nftScanned; 
    mapping (uint256 => address) private _ticketIssuerAddresses;  
    mapping (uint256 => address) private _eventAddresses;

    event txPrimaryMint(address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txScan(address originAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event doubleScan(address indexed originAddress, uint256 indexed nftIndex, uint indexed _timestamp);
    event doubleNFTAlert(address indexed destinationAddress, uint indexed _timestamp);
    event noCoinerAlert(address indexed originAddress, uint indexed _timestamp);
    event illegalTransfer(address indexed originAddress,address indexed destinationAddress,uint256 indexed nftIndex, uint _timestamp);



    // Whtielisted EOA account with "ADMIN" role
    modifier onlyAdmin() {
        require(BOUNCER.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ACCESS DENIED - Restricted to admins of GET Protocol.");
        _;
    }

    // Whtielisted EOA account with "RELAYER" role
    modifier onlyRelayer() {
        require(BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ACCESS DENIED - Restricted to relayers of GET Protocol.");
        _;
    }

    // Whtielisted EOA account with "MINTER" role
    modifier onlyMinter() {
        require(BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ACCESS DENIED - Restricted to minters of GET Protocol.");
        _;
    }
    
    // Whitelisted Contract Address - A factory mints/issues getNFTs (the contract you are looking at). 
    modifier onlyFactory() {
        require(BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ACCESS DENIED - Restricted to registered getNFT Factory contracts.");
        _;
    }

    /** 
     * @dev Set event_metadata_TE_address for NFT Factory contract (used to store metadata of events and ticketIssuer - TE)
     */ 
    function updategetNFTMetaDataIssuersEvents(address _new_metadata_TE) public onlyAdmin() {
        METADATA_IE = MetaDataIssuersEvents(_new_metadata_TE);
    }

    function updateBouncerContract(address _new_bouncer_address) public onlyAdmin() {
        BOUNCER = AccessContractGET(_new_bouncer_address);
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) public onlyRelayer() returns(bool success) {
        return METADATA_IE.newTicketIssuer(ticketIssuerAddress, ticketIssuerName, ticketIssuerUrl);
    }

    /** 
     * @dev Register address data of new event
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory latitude, string memory longitude, uint256 startingTime, address tickeerAddress, string memory callbackUrl) public onlyRelayer() returns(bool success) {
        return METADATA_IE.registerEvent(eventAddress, eventName, shopUrl, latitude, longitude, startingTime, tickeerAddress, callbackUrl);
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function getEventDataAll(address eventAddress) public view returns(string memory eventName, string memory shopUrl, uint startTime, string memory ticketIssuerName, address, string memory ticketIssuerUrl) {
        return METADATA_IE.getEventDataAll(eventAddress);
    }


    /**  onlyRelayer - caller needs to be whitelisted relayer
    * @notice In the first transaction the ticketMetadata is stored in the metadata of the NFT.
    * @param destinationAddress addres of the to-be owner of the getNFT 
    * @param ticketMetadata string containing the metadata about the ticket the NFT is representing (unstructured, set by ticketIssuer)
    */
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata) public onlyRelayer() returns (uint256) {

        // Check if the destinationAddress already owns getNFTs (this would be weird!)
        if (balanceOf(destinationAddress) != 0) {
            emit doubleNFTAlert(destinationAddress, block.timestamp);
        }
        
        /// Fetch nftIndex, autoincrement & mint
        _nftIndexs.increment();
        uint256 nftIndex = _nftIndexs.current();
        _mint(destinationAddress, nftIndex);

        // Storing the address of the ticketIssuer in the getNFT
        _markTicketIssuerAddress(nftIndex, ticketIssuerAddress);
        
        // Storing the address of the event in the getNFT
        _markEventAddress(nftIndex, eventAddress);
        
        /// Storing the ticketMetadata in the NFT        
        _setnftMetadata(nftIndex, ticketMetadata);
        
        // Set scanned state to false (unscanned state)
        _setnftScannedBool(nftIndex, false);

        // Push Order data primary sale to metadata contract
        METADATA_IE.addNftMeta(eventAddress, nftIndex, 50);
        
        // Fetch blocktime as to assist ticket explorer for ordering
        emit txPrimaryMint(destinationAddress, ticketIssuerAddress, nftIndex, block.timestamp);
        
        return nftIndex;
    }


    /** 
    * @notice This function can only be called by a whitelisted relayer address (onlyRelayer).
    * @notice The nftIndex will be fetched by the contract using ownerOf(originAddress)
    * @param originAddress address of the current owner of the getNFT
    * @param destinationAddress addres of the to-be owner of the NFT 
    */
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer() {

        // In order to transfer an getNFT, the origin needs to own an NFT
        if (balanceOf(originAddress) == 0) {
            emit noCoinerAlert(originAddress, block.timestamp);
            return; // return function as it will fail otherwise (no nft to transfer)
        }

        uint256 nftIndex;
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        // /// Verify if originAddress is owner of nftIndex
        require(ownerOf(nftIndex) == originAddress, "GET TX FAILED Func: secondaryTransfer - transfer of nftIndexx that is not owned by owner");
        
        // Check if the destinationAddress already owns getNFTs (this would be weird!)
        if (ownerOf(nftIndex) != originAddress) {
            emit illegalTransfer(originAddress, destinationAddress, nftIndex, block.timestamp);
            return;
        }        
        
        /// Transfer the NFT to destinationAddress
        _relayerTransferFrom(originAddress, destinationAddress, nftIndex);

        // Push Order data secondary sale to metadata contract
        // address _eventAddress;
        // _eventAddress = _eventAddresses[nftIndex];
        // METADATA_IE.addnftIndex(_eventAddress, nftIndex, 60);

        /// Emit event of secondary transfer
        emit txSecondary(originAddress, destinationAddress, getAddressOfTicketIssuer(nftIndex), nftIndex, block.timestamp);
    }

    /** onlyRelayer - caller needs to be whitelisted relayer
    * @notice Returns the NFT of the ticketIssuer back to its address + cleans the ticketMetadata from the NFT 
    * @notice Function doesn't require autorization/sig of the NFT owner!
    * @dev Only a whitelisted relayer address is able to call this contract (onlyRelayer).
    */
    function scanNFT(address originAddress) public onlyRelayer() {

        uint256 nftIndex; 
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        address destinationAddress = getAddressOfTicketIssuer(nftIndex);

        bool statusNft;
        statusNft = _nftScanned[nftIndex];

        if (statusNft != true) {
            // The getNFT has already been scanned. This is allowed, but needs to be displayed in the event feed.
            emit doubleScan(originAddress, nftIndex, block.timestamp);
            return; 
        }

        // Set scanned state to true 
        _setnftScannedBool(nftIndex, true);
        
        emit txScan(originAddress, destinationAddress, nftIndex, block.timestamp);
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
     * @dev Internal function that stores the eventAddress in the NFT metadata 
     * @notice Storage of the eventAddress is immutable
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
     */
    function _setnftScannedBool (uint256 nftIndex, bool status) internal {
        require(_exists(nftIndex), "GET TX FAILED Func: _setnftScannedBool: Nonexistent nftIndex");
        _nftScanned[nftIndex] = status;
    }    

}