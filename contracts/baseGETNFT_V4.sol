pragma solidity ^0.6.2;

pragma experimental ABIEncoderV2;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/CountersUpgradeable.sol";

import "./interfaces/IgetNFT_ERC721.sol";

contract baseGETNFT_V4 is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    
    function initialize_base(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721
        ) public virtual initializer {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        METADATA = IMetadataStorage(address_metadata);
        FINANCE = IEventFinancing(address_finance);
        GET_ERC721 = IGET_ERC721(address_erc721);
    }

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    mapping (uint256 => TicketData) private _ticket_data;

    struct TicketData {
        address event_address;
        bool scanned;
        bool valid;
        bytes32[] ticket_metadata;
        bool set_aside;
        uint256[] prices_sold;
    }

    event primarySaleMint(
        uint256 indexed nftIndex,
        address indexed destinationAddress, 
        address indexed eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event secondarySale(
        uint256 indexed nftIndex,
        address originAddress,
        address indexed destinationAddress, 
        address indexed eventAddress,
        uint256 secondaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event saleCollaterizedIntentory(
        uint256 nftIndex,
        address underwriterAddress,
        address indexed destinationAddress, 
        address indexed eventAddress,
        uint256 indexed primaryPrice,
        uint256 orderTime,
        uint _timestamp 
    );

    event ticketScanned(
        uint256 indexed nftIndex, 
        address originAddress, 
        address indexed eventAddress, 
        uint _timestamp
    );

    event ticketInvalidated(
        uint256 indexed nftIndex, 
        address indexed originAddress,
        uint indexed _timestamp
    ); 

    event nftMinted(
        uint256 nftIndex,
        address destinationAddress, 
        uint _timestamp
    );

    event nftTokenURIEdited(
        uint256 nftIndex,
        address originAddress,
        string _netTokenURI,
        uint _timestamp
    );

    event nftClaimed(
        uint256 nftIndex,
        address originAddress, 
        address externalAddress
    );


    /**
    @dev primary sale function, moves or mints getNFT to wallet of fan/user
    @notice this function is always called by flusher when a primary sale takes plac
    @notice depending on the metadata variables stored in the EventStruct object, the function mints or un-colleterizes
    @param destinationAddress address of the ticket buyer 
    @param eventAddress address of the event
    @param primaryPrice ticket price paid by primary buyer, in the local currency as set in EventStruct
    @param orderTime time epoch of the sale as passed on by flusher
    @param ticketURI string referencing unique data that is stored when minting
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        string memory ticketURI, 
        bytes32[] memory ticketMetadata
    ) public returns (uint256 nftIndex) {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "primarySale: ILLEGAL RELAYER");

        bool _state = false;
        _state = METADATA.isInventoryUnderwritten(eventAddress);
        
        if (_state == true) {  
            // Ticket inventory is 'set aside' - getNFTs already minted, inventory of event is collateralized.
            
            // fetch underWriter address from metadata contract
            address underwriterAddress = METADATA.getUnderwriterAddress(eventAddress);
            
            nftIndex = GET_ERC721.tokenOfOwnerByIndex(underwriterAddress, 0);

            require(_ticket_data[nftIndex].valid == true, "primarySale - NFT INVALIDATED"); 
            require(GET_ERC721.ownerOf(nftIndex) == underwriterAddress, "primarySale - WRONG UNDERWRITER");   

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

            // push sale data to metadata of getNFT
            _ticket_data[nftIndex].prices_sold.push(primaryPrice);

            emit saleCollaterizedIntentory(
                nftIndex,
                underwriterAddress,
                destinationAddress, 
                eventAddress, 
                primaryPrice,
                orderTime,
                block.timestamp
            );

            return nftIndex;

            } else {

            // Event NFT is created for is not colleterized, getNFT minted to user 
            nftIndex = mintGETNFT( 
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
                destinationAddress,
                eventAddress,
                primaryPrice,
                orderTime,
                block.timestamp
            );

            _ticket_data[nftIndex].prices_sold.push(primaryPrice);
        }

        return nftIndex;
            
    }

    /**
    @notice function can be called internally as well as from finacing contract
    */
    function mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
    ) public returns(uint256 nftIndex) {

        // TODO Change to MINTER
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "mintGETNFT: ILLEGAL RELAYER");

        nftIndex = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        TicketData storage tdata = _ticket_data[nftIndex];
        tdata.event_address = eventAddress;
        tdata.scanned = false;
        tdata.valid = true;
        tdata.ticket_metadata = ticketMetadata;
        tdata.set_aside = setAsideNFT;
        
        emit nftMinted(
            nftIndex,
            destinationAddress, 
            block.timestamp
        );

        return nftIndex;
    }

    function editTokenURI(
        address originAddress,
        string memory _newTokenURI
        ) public {
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
            GET_ERC721.editTokenURI(nftIndex, _newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                originAddress,
                _newTokenURI,
                block.timestamp
            );
        }

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "secondaryTransfer: WRONG RELAYER");

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(_ticket_data[nftIndex].valid == true, "secondaryTransfer: ALREADY INVALIDATED");
        require(GET_ERC721.ownerOf(nftIndex) == originAddress, "secondaryTransfer: INVALID NFT OWNER");     
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            originAddress, 
            destinationAddress, 
            _ticket_data[nftIndex].event_address, 
            secondaryPrice,
            orderTime,
            block.timestamp
        );
    
    }

    function scanNFT(address originAddress) public {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        // TODO: CHECK IF originaAddress has a getNFT balance
        // if (balanceOf(originAddress) == 0) {
        //     emit illegalScan(nftIndex);
        //     return; // return function as it will fail otherwise (no nft to scan)
        // }

        require(_ticket_data[nftIndex].valid == true, "scanNFT: NFT INVALIDATED");

        // TODO: CHECK IF nftIndex has already been scanned
        // if (_ticketInfo[nftIndex].valid == true) {
        //     // The getNFT has already been scanned. This is allowed, but needs to be displayed in the event feed.
        //     emit illegalScan(nftIndex);
        //     return; 
        // }

        _ticket_data[nftIndex].scanned = true;

        emit ticketScanned(
            nftIndex, 
            originAddress, 
            _ticket_data[nftIndex].event_address, 
            block.timestamp
        );
    }

    function invalidateAddressNFT(address originAddress) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "invalidateAddressNFT: WRONG RELAYER");
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(_ticket_data[nftIndex].valid != false, "invalidateAddressNFT - ALREADY INVALIDATED");
        _ticket_data[nftIndex].valid = false;

        emit ticketInvalidated(
            nftIndex, 
            originAddress, 
            block.timestamp
        );
    } 


    function claimgetNFT(
        address originAddress, 
        address externalAddress) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "claimgetNFT: WRONG RELAYER");

        require(GET_ERC721.balanceOf(originAddress) != 0, "claimgetNFT: NO BALANCE");

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT

        bool _claimable = isNFTClaimable(nftIndex, originAddress);

        require(_claimable == false, "claimgetNFT - ILLEGAL ClAIM");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        // emit event of successfull 
        emit nftClaimed(
            nftIndex,
            originAddress, 
            externalAddress
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
        return true;
    }

    function ticketMetadata(address originAddress)
      public 
      virtual 
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      )
      {
          uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
          _ticketMetadata = tdata.ticket_metadata;
          _setAsideNFT = tdata.set_aside;
          _prices_sold = tdata.prices_sold;
      }

}
