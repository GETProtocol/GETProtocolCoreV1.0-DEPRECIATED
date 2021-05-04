pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/CountersUpgradeable.sol";

import "./utils/SafeMathUpgradeable.sol";

import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";

import "./interfaces/IGETAccessControl.sol";

contract baseGETNFT_V6 is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;

    using SafeMathUpgradeable for uint256;
    
    function initialize_base(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721,
        address address_economics
        ) public virtual initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            METADATA = IMetadataStorage(address_metadata);
            FINANCE = IEventFinancing(address_finance);
            GET_ERC721 = IGET_ERC721(address_erc721);
            ECONOMICS = IEconomicsGET(address_economics);
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    mapping (uint256 => TicketData) private _ticket_data;

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside;
        bool scanned;
        bool valid;
    }

    event ConfigurationChanged(
        address addressBouncer, 
        address addressMetadata, 
        address addressFinance,
        address addressERC721,
        address addressEconomics
    );

    event primarySaleMint(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 indexed orderTime
    );

    event secondarySale(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address destinationAddress, 
        address eventAddress,
        uint256 secondaryPrice,
        uint256 indexed orderTime
    );

    event saleCollaterizedIntentory(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address underwriterAddress,
        address destinationAddress, 
        address eventAddress,
        uint256 primaryPrice,
        uint256 indexed orderTime
    );

    event ticketScanned(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        uint256 indexed orderTime
    );

    event ticketInvalidated(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address originAddress,
        uint256 indexed orderTime
    ); 

    event nftClaimed(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address externalAddress,
        uint256 indexed orderTime
    );

    event nftMinted(
        uint256 indexed nftIndex,
        address indexed destinationAddress, 
        uint timestamp
    );

    event nftTokenURIEdited(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        string netTokenURI,
        uint timestamp
    );

    event illegalScan(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        uint256 indexed orderTime
    );

    /**
    @dev primary sale function, moves or mints getNFT to EOA of a ticket buyer
    @notice this function is always called by flusher when a primary sale takes place
    @notice internal logic (based on metadata of event) will determine the flow/code that is executed
    @param destinationAddress address of the ticket buyer (EOA)
    @param eventAddress address of the event (EOA)
    @param primaryPrice TODO
    @param orderTime TODO
    @param ticketURI TODO
    @param ticketMetadata TODO
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external onlyRelayer returns (uint256 nftIndex) {

        bool _state = false;
        _state = METADATA.isInventoryUnderwritten(eventAddress);

        // Ticket inventory is 'set aside' - getNFTs already minted, inventory of event is collateralized.
        if (_state == true) {  
            
            // fetch underWriter address from metadata contract
            address underwriterAddress = METADATA.getUnderwriterAddress(eventAddress);
            
            nftIndex = GET_ERC721.tokenOfOwnerByIndex(underwriterAddress, 0);

            require(_ticket_data[nftIndex].valid == true, "primarySale - NFT INVALIDATED"); 
            require(GET_ERC721.ownerOf(nftIndex) == underwriterAddress, "primarySale - INCORRECT UNDERWRITER");   

            // getNFT transfer is relayed to FINANCE contract, as to perform accounting
            FINANCE.collateralizedNFTSold(
                nftIndex,
                underwriterAddress,
                destinationAddress,
                orderTime,
                primaryPrice     
            );

            GET_ERC721.relayerTransferFrom(
                underwriterAddress, 
                destinationAddress, 
                nftIndex
            );

            // push/append colleterization price to getNFT 
            _ticket_data[nftIndex].prices_sold.push(primaryPrice);

            emit saleCollaterizedIntentory(
                nftIndex,
                10000, // placeholder GET usage
                underwriterAddress,
                destinationAddress, 
                eventAddress, 
                primaryPrice,
                orderTime
            );

            return nftIndex;

            } else {

                // Event NFT is created for is not colleterized, getNFT minted to user 
                nftIndex = _mintGETNFT( 
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime,
                    ticketURI,
                    ticketMetadata,
                    false 
                );

                emit primarySaleMint(
                    nftIndex,
                    10000, 
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime
                );

                // push/append primary market sale data to getNFT
                _ticket_data[nftIndex].prices_sold.push(primaryPrice);
        }

        return nftIndex;
            
    }

    /**
    @dev function relays mint transaction from FINANCE contract to internal function _mintGETNFT
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param eventAddress primary key of event (EOA account)
    @param pricepaid TODO
    @param orderTime TODO
    @param ticketURI  TODO
    @param ticketMetadata TODO
    @param setAsideNFT TODO
    */
    function relayColleterizedMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
    ) external onlyRelayer returns (uint256 nftIndex) {

        nftIndex = _mintGETNFT(
            destinationAddress,
            eventAddress,
            pricepaid,
            orderTime,
            ticketURI,
            ticketMetadata,
            setAsideNFT
        );
    }
    
    function changeConfiguration(
        address newAddressBouncer,
        address newAddressMetadata,
        address newAddressFinance,
        address newAddressERC721,
        address newAddressEconomics
    ) external onlyAdmin {
        
        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        METADATA = IMetadataStorage(newAddressMetadata);
        FINANCE = IEventFinancing(newAddressFinance);
        GET_ERC721 = IGET_ERC721(newAddressERC721);
        ECONOMICS = IEconomicsGET(newAddressEconomics);

        emit ConfigurationChanged(
            newAddressBouncer,
            newAddressMetadata,
            newAddressFinance,
            newAddressERC721,
            newAddressEconomics
        );
    }

    /**
    @dev mints getNFT
    @notice this function can be called internally, as well as externally (in case of event financing)
    @param destinationAddress TODO
    @param eventAddress TODO
    @param pricepaid TODO
    @param orderTime TODO
    @param ticketURI TODO
    @param ticketMetadata TODO
    @param setAsideNFT TODO
    */
    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
        ) internal returns(uint256 nftIndex) {

        nftIndex = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        TicketData storage tdata = _ticket_data[nftIndex];
        tdata.ticket_metadata = ticketMetadata;
        tdata.event_address = eventAddress;
        tdata.set_aside = setAsideNFT;
        tdata.scanned = false;
        tdata.valid = true;
        
        emit nftMinted(
            nftIndex,
            destinationAddress, 
            block.timestamp
        );

        return nftIndex;
    }


    /**
    @dev edits URI of getNFT
    @notice select getNFT by address TODO POSSIBLY REMOVE/RETIRE
    @param originAddress TODO
    @param newTokenURI TODO
    */
    function editTokenURIbyAddress(
        address originAddress,
        string calldata newTokenURI
        ) external onlyRelayer {
            
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
            
            require(nftIndex >= 0, "editTokenURI !nftIndex");
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                10000,
                newTokenURI,
                block.timestamp
            );
        }

    /**
    @dev edits URI of getNFT
    @notice select getNFT by the nftIndex
    @param nftIndex TODO
    @param newTokenURI TODO
    */
    function editTokenURIbyIndex(
        uint256 nftIndex,
        string calldata newTokenURI
        ) external onlyRelayer {

            require(nftIndex >= 0, "editTokenURI !nftIndex");
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                10000,
                newTokenURI,
                block.timestamp
            );
        }


    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        
        require(nftIndex >= 0, "scanNFT !nftIndex");

        require(_ticket_data[nftIndex].valid == true, "secondaryTransfer: ALREADY INVALIDATED");

        require(GET_ERC721.ownerOf(nftIndex) == originAddress, "secondaryTransfer: INVALID NFT OWNER");     
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            10000,
            destinationAddress, 
            _ticket_data[nftIndex].event_address, 
            secondaryPrice,
            orderTime
        );
    
    }

    function scanNFT(
        address originAddress, 
        uint256 orderTime
        ) external onlyRelayer returns(bool) {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex >= 0, "scanNFT !nftIndex");

        require(_ticket_data[nftIndex].valid == true, "scanNFT: NFT INVALIDATED");

        if (_ticket_data[nftIndex].scanned == true) {
            // The getNFT has already been scanned
            emit illegalScan(
                nftIndex,
                1000,
                orderTime
            );

            return false; 
        }

        _ticket_data[nftIndex].scanned = true;

        emit ticketScanned(
            nftIndex,
            10000,
            orderTime
        );

        return true;
    }

    function invalidateAddressNFT(
        address originAddress, 
        uint256 orderTime) external onlyRelayer {

        // require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "invalidateAddressNFT: !RELAYER");
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        require(nftIndex >= 0, "invalidateAddressNFT !nftIndex");

        require(_ticket_data[nftIndex].valid != false, "invalidateAddressNFT - ALREADY INVALIDATED");
        _ticket_data[nftIndex].valid = false;

        emit ticketInvalidated(
            nftIndex, 
            10000,
            originAddress,
            orderTime
        );
    } 

    function claimgetNFT(
        address originAddress, 
        address externalAddress,
        uint256 orderTime) external onlyRelayer {

        require(GET_ERC721.balanceOf(originAddress) != 0, "claimgetNFT: NO NFT BALANCE");

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT
        require(nftIndex >= 0, "claimgetNFT !nftIndex");

        bool _claimable = isNFTClaimable(nftIndex, originAddress);

        require(_claimable == false, "claimgetNFT - ILLEGAL ClAIM");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        emit nftClaimed(
            nftIndex,
            10000, // get usage placeholder
            externalAddress,
            orderTime
        );

    }

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {
        if (_ticket_data[nftIndex].valid == true) {
            return false;
        }
        if (_ticket_data[nftIndex].scanned == false) {
            return false;
        }
        if (GET_ERC721.ownerOf(nftIndex) != ownerAddress) {
            return false;
        }
        else {
            return true;
        }
        
    }

    function ticketMetadata(
        address originAddress)
      public virtual view returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      )
      {
          uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
          require(nftIndex >= 0, "scanNFT !nftIndex");
          
          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
          _ticketMetadata = tdata.ticket_metadata;
          _setAsideNFT = tdata.set_aside;
          _prices_sold = tdata.prices_sold;
      }

}
