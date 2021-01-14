pragma solidity ^0.6.0;

import "./ERC721_CLEAN.sol";
import "./Counters.sol";
import "./interfaces/IERCAccessControlGET.sol";
// import "./Initializable.sol";
import "./bouncerLogic.sol";
import "./metadata/metadataLogic.sol";
 
abstract contract ERC721_TICKETING_V3 is ERC721_CLEAN, metadataLogic, bouncerLogic {

    constructor () public ERC721_CLEAN("GET PROTOCOL SMART TICKET FACTORY V3", "getNFT BSC V3", "https://get-protocol.io/") {
        BOUNCER = AccessContractGET(0xaC2D9016b846b09f441AbC2756b0895e529971CD); 
    }

    using Counters for Counters.Counter;
    Counters.Counter private _nftIndexs;

    mapping(uint256 => bool) public _nftScanned; 
    mapping(uint256 => bool) public _nftInvalidated; 
    mapping (uint256 => address) private _ticketIssuerAddresses;  
    mapping (uint256 => address) private _eventAddresses;

    // Primary market ticket sold/issued.
    event txPrimaryMint(address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    // Secondary market ticket traded/shared.
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    // Ticket scanned/validated.
    event txScan(address originAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    //  An already valid ticket was scanned again.
    event doubleScan(address indexed originAddress, uint256 indexed nftIndex, uint indexed _timestamp);
    // An destinationAddress already owns an getNFT (unusual due to rotation of fresh keys)
    event doubleNFTAlert(address indexed destinationAddress, uint indexed _timestamp);
    // System wrongly assumes an originAddress owns an getNFT (owns none)
    event noCoinerAlert(address indexed originAddress, uint indexed _timestamp);
    // System wrongly assumes an originAddress owns an getNFT (doesn't own this one)
    event illegalTransfer(address indexed originAddress,address indexed destinationAddress,uint256 indexed nftIndex, uint _timestamp);
    // System attempts to scan an NFT on an orginAddress that isnt there
    event illegalScan(address indexed originAddress, uint indexed _timestamp);
    // System attempts to invalidate an NFT that is already invalidated
    event nftInvalidated(uint256 indexed nftIndex, uint indexed _timestamp);

    /**  onlyRelayer - caller needs to be whitelisted relayer
    * @notice In the first transaction the ticketMetadata is stored in the metadata of the NFT.
    * @param destinationAddress addres of the to-be owner of the getNFT 
    * @param ticketMetadata string containing the metadata about the ticket the NFT is representing (unstructured, set by ticketIssuer)
    * @param orderTime timestamp of the moment the ticket-twin was sold in the primary market by ticketIssuer
    */
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata, uint256 orderTime) public onlyRelayer() returns (uint256) {

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

        // Set invalidated bool to false (not invalidated)
        _setnftInvalidBool(nftIndex, false);

        // Push Order data primary sale to metadata contract
        addNftMetaPrimary(eventAddress, nftIndex, orderTime, 50);
        
        // Fetch blocktime as to assist ticket explorer for ordering
        emit txPrimaryMint(destinationAddress, ticketIssuerAddress, nftIndex, block.timestamp);
        
        return nftIndex;
    }


    /**
    * @dev invalidates the nft, making it impossible to move
    * @param originAddress address of getNFT owner to be invalidated
     */
    function invalidateAddressNFT(address originAddress) public onlyRelayer() {
        
        uint256 nftIndex;
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        // set invalidated to true
        // _nftInvalidated[nftIndex] = true;
        require(_nftInvalidated[nftIndex] != true, "GET TX FAILED Func: invalidateAddressNFT - getNFT is is already set to true");
        _setnftInvalidBool(nftIndex, true);

        emit nftInvalidated(nftIndex, block.timestamp);
    }

    /**
    * @dev invalidates the nft, making it impossible to move
    * @param nftIndex  index of getNFT to be invalidated
     */
    function invalidateIndexNFT(uint256 nftIndex) public onlyRelayer() {

        // set invalidated to true
        // _nftInvalidated[nftIndex] = true;

        require(_nftInvalidated[nftIndex] != true, "GET TX FAILED Func: invalidateIndexNFT - getNFT is is already set to true");
        _setnftInvalidBool(nftIndex, true);

        emit nftInvalidated(nftIndex, block.timestamp);
    }

    /** 
    * @notice This function can only be called by a whitelisted relayer address (onlyRelayer).
    * @notice The nftIndex will be fetched by the contract using ownerOf(originAddress)
    * @param originAddress address of the current owner of the getNFT
    * @param destinationAddress address of the to-be(future) owner of the getNFT 
    * @param orderTime timestamp of the moment the ticket-twin was sold in the secondary market by ticketIssuer
    */
    function secondaryTransfer(address originAddress, address destinationAddress, uint256 orderTime) public onlyRelayer() {

        // In order to transfer an getNFT, the origin needs to own an NFT
        if (balanceOf(originAddress) == 0) {
            emit noCoinerAlert(originAddress, block.timestamp);
            return; // return function as it will fail otherwise (no nft to transfer)
        }

        uint256 nftIndex;
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        require(_nftInvalidated[nftIndex] == false, "GET TX FAILED Func: secondaryTransfer - getNFT is marked as invalidated");

        // Verify if originAddress is owner of nftIndex
        require(ownerOf(nftIndex) == originAddress, "GET TX FAILED Func: secondaryTransfer - transfer of nftIndexx that is not owned by owner");
        
        // Check if the destinationAddress already owns getNFTs (this would be weird!)
        if (ownerOf(nftIndex) != originAddress) {
            emit illegalTransfer(originAddress, destinationAddress, nftIndex, block.timestamp);
            return;
        }        
        
        /// Transfer the NFT to destinationAddress
        _relayerTransferFrom(originAddress, destinationAddress, nftIndex);

        // Push Order data secondary sale to metadata contract
        address _eventAddress;
        _eventAddress = _eventAddresses[nftIndex];
        addNftMetaSecondary(_eventAddress, nftIndex, orderTime, 60);

        /// Emit event of secondary transfer
        emit txSecondary(originAddress, destinationAddress, getAddressOfTicketIssuer(nftIndex), nftIndex, block.timestamp);
    }

    /** onlyRelayer - caller needs to be whitelisted relayer
    * @notice Returns the NFT of the ticketIssuer back to its address + cleans the ticketMetadata from the NFT 
    * @notice Function doesn't require autorization/sig of the NFT owner!
    * @dev Only a whitelisted relayer address is able to call this contract (onlyRelayer).
    */
    function scanNFT(address originAddress) public onlyRelayer() {

        if (balanceOf(originAddress) == 0) {
            emit illegalScan(originAddress, block.timestamp);
            return; // return function as it will fail otherwise (no nft to scan)
        }

        uint256 nftIndex; 
        nftIndex = tokenOfOwnerByIndex(originAddress, 0);

        require(_nftInvalidated[nftIndex] == false, "GET TX FAILED Func: scanNFT - getNFT is marked as invalidated");

        address destinationAddress = getAddressOfTicketIssuer(nftIndex);

        bool statusNft;
        statusNft = _nftScanned[nftIndex];

        if (statusNft == true) {
            // The getNFT has already been scanned. This is allowed, but needs to be displayed in the event feed.
            emit doubleScan(originAddress, nftIndex, block.timestamp);
            return; 
        }

        // Set scanned state to true 
        _setnftScannedBool(nftIndex, true);
        
        emit txScan(originAddress, destinationAddress, nftIndex, block.timestamp);
    }


    /** 
     * @dev returns metadata fields getNFT by orginAddress
     * @notice if an address owned an getNFT in the past, but not anymore, this will return empty
     */
    function getNFTByAddress(address originAddress) public view returns(uint256 nftIndex, bool _scanState, address _ticketIssuerA, address _eventAddress, string memory _metadata) { 
        require(balanceOf(originAddress) != 0, "GET TX FAILED Func: getNFTByAddress - URI query for nonexistent token.");
        return(
            tokenOfOwnerByIndex(originAddress, 0),
            _nftScanned[nftIndex],
            _ticketIssuerAddresses[nftIndex],
            _eventAddresses[nftIndex],
            _tokenURIs[nftIndex]);
    }


    /** 
     * @dev returns all metadata of getNFT by nftIndex
     */
    function getNFTByIndex(uint256 nftIndex) public view returns(address _originAddress, bool _scanState, address _ticketIssuerA, address _eventAddress, string memory _metadata) { 
        require(_exists(nftIndex), "GET TX FAILED Func: getNFTByIndex - Query for nonexistent token");
        return(
            ownerOf(nftIndex),
            _nftScanned[nftIndex],
            _ticketIssuerAddresses[nftIndex],
            _eventAddresses[nftIndex],
            _tokenURIs[nftIndex]);
    }

    /** 
     * @dev updates bouncer contract used to validate all incoming txs/calls 
     */
    function updateBouncerContract(address _new_bouncer_address) public onlyAdmin() {
        BOUNCER = AccessContractGET(_new_bouncer_address);
    }

    /** 
     * @dev Register address data of new ticketIssuer
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) public override onlyRelayer() returns(bool success) {
        return super.newTicketIssuer(ticketIssuerAddress, ticketIssuerName, ticketIssuerUrl);
    }

    /** 
     * @dev Register address data of new event
     * @notice Data will be publically available for the getNFT ticket explorer. 
     */ 
    function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory latitude, string memory longitude, uint256 startingTime, address ticketIssuer, string memory callbackUrl) public override onlyRelayer() returns(bool success) {
        return super.registerEvent(eventAddress, eventName, shopUrl, latitude, longitude, startingTime, ticketIssuer, callbackUrl);
    }

    function addNftMetaPrimary(address eventAddress, uint256 nftIndex, uint256 orderTimeP, uint256 pricePaidP) public override onlyRelayer() returns(bool success) {
        return super.addNftMetaPrimary(eventAddress, nftIndex, orderTimeP, pricePaidP);
    }

    function addNftMetaSecondary(address eventAddress, uint256 nftIndex, uint256 orderTimeS, uint256 pricePaidS) public override onlyRelayer() returns(bool success) {
        return super.addNftMetaSecondary(eventAddress, nftIndex, orderTimeS, pricePaidS);
    }

    /**
    * @dev Returns the address of the ticketIssuerAddress that controls the NFT
     */
    function getAddressOfTicketIssuer(uint256 nftIndex) public view returns (address) {
        require(_exists(nftIndex), "GET TX FAILED Func: getAddressOfTicketIssuer : Nonexistent nftIndex");
        return _ticketIssuerAddresses[nftIndex];
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
    * @dev Returns the Eventaddress of the getNFT
    */
    function getEventAddress(uint256 nftIndex) public view returns (address) {
        require(_exists(nftIndex), "GET TX FAILED Func: getEventAddress : Nonexistent nftIndex");
        return _eventAddresses[nftIndex];
    }

    /**
    * @dev Sets a getNFT metadata value to true/false.
     */
    function _setnftScannedBool(uint256 nftIndex, bool status) internal {
        // require(_exists(nftIndex), "GET TX FAILED Func: _setnftScannedBool: Nonexistent nftIndex");
        _nftScanned[nftIndex] = status;
    }    

    /**
    * @dev Sets a getNFT invalid state to true/false.
     */
    function _setnftInvalidBool(uint256 nftIndex, bool status) internal {
        // require(_exists(nftIndex), "GET TX FAILED Func: _setnftScannedBool: Nonexistent nftIndex");
        _nftInvalidated[nftIndex] = status;
    }        

}