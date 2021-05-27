pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/CountersUpgradeable.sol";

import "./utils/SafeMathUpgradeable.sol";
import "./interfaces/IticketFuelDepotGET.sol";

import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";

import "./interfaces/IGETAccessControl.sol";

/**

                    ####
                  ###  ###
                ####     ###
              ###  ###    ###
            ####     ###    ###
          ###  ###     ###    ###
        ####     ###     ###   ##
      ###  ###     #################
     ###     ###     ###           ##
      ###      ###     ###         ##
        ###      ##########      ###
          ###      ######      ###
            ###      ##      ###
              ###          ###
                ###      ###
                  ###  ###
                    ####

           #####  ####  #####  
          #       #       #   
          #  ###  ####    #    
          #    #  #       #        
           #####  ####    #  
 
            GOT GUTS? GET PROTOCOL IS HIRING!
      -----------------------------------
         info (at) get-protocol (dot) io

*/

contract baseGETNFT_V6 is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;
    IticketFuelDepotGET public DEPOT;

    using SafeMathUpgradeable for uint256;
    
    function initialize_base(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721,
        address address_economics,
        address address_fueldepot
        ) public virtual initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            METADATA = IMetadataStorage(address_metadata);
            FINANCE = IEventFinancing(address_finance);
            GET_ERC721 = IGET_ERC721(address_erc721);
            ECONOMICS = IEconomicsGET(address_economics);
            DEPOT = IticketFuelDepotGET(address_fueldepot);
    }

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant GET_ADMIN = keccak256("GET_ADMIN");

    // TODO CONSIDER MAKING PRIVATE
    mapping (uint256 => TicketData) private _ticket_data;

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside; // true = collaterized 
        bool scanned; // true = ticket is scanned, false = ticket is unscanned
        bool valid; // true = ticket can be used,sold,claimed. false = ticket has been invalidated for whatever reason by issuer. 
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
        address eventAddress,
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
        address indexed destinationAddress
    );

    event nftTokenURIEdited(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        string netTokenURI
    );

    event illegalScan(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        uint256 indexed orderTime
    );

    event colleterizedMint(
        uint256 indexed nftIndex,
        uint256 indexed getUsed,
        address destinationAddress, 
        address eventAddress, 
        uint256 strikeValue,
        uint256 indexed orderTime
    );

    // MODIFIERS BASE GETNFT V6 //

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
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    // FUNCTIONS BASE GETNFT V6 //

    /**
    @dev primary sale function, transfers or mints NFT to EOA of a primary market ticket buyer
    @notice function called directly by relayer or via financing contract
    @notice path determined by event config in metadata contract
    @param destinationAddress EOA address of the ticket buyer (GETcustody)
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
    @param primaryPrice price paid by primary ticket buyer in the local/event currenct
    @param basePrice price as charged to the ticketeer in USD 
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 

    @return nftIndexP as assigned by the contract when minted
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external onlyRelayer returns (uint256 nftIndexP) {

        if (METADATA.isInventoryUnderwritten(eventAddress)) { 

             // Ticket inventory is 'set aside' - getNFTs already minted, inventory of event is collateralized.
            
            // fetch underWriter address from metadata contract
            address underwriterAddress = METADATA.getUnderwriterAddress(eventAddress);
            
            nftIndexP = GET_ERC721.tokenOfOwnerByIndex(underwriterAddress, 0);

            require(isNFTSellable(nftIndexP, underwriterAddress), "RE/SALE_ERROR");

            uint256 charged = DEPOT.chargeProtocolTax(nftIndexP);

            // getNFT transfer is relayed to FINANCE contract, as to perform accounting
            FINANCE.collateralizedNFTSold(
                nftIndexP,
                underwriterAddress,
                destinationAddress,
                orderTime,
                primaryPrice     
            );

            GET_ERC721.relayerTransferFrom(
                underwriterAddress, 
                destinationAddress, 
                nftIndexP
            );

            // push/append colleterization price to getNFT 
            _ticket_data[nftIndexP].prices_sold.push(primaryPrice);

            emit saleCollaterizedIntentory(
                nftIndexP,
                charged,
                eventAddress, 
                orderTime
            );

            return nftIndexP;

            } else {

                // Event NFT is created for is not colleterized, getNFT minted to user 
                nftIndexP = _mintGETNFT( 
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime,
                    ticketURI,
                    ticketMetadata,
                    false 
                );

                // // fuel the tank of the NFT, passing on the base price
                // uint256 reserved = ECONOMICS.fuelBackpackTicket(
                //     nftIndexP,
                //     msg.sender,
                //     basePrice
                // );

                // charge the protocol tax rate on the tank balance
                uint256 charged = DEPOT.chargeProtocolTax(nftIndexP);

                emit primarySaleMint(
                    nftIndexP,
                    charged,
                    destinationAddress,
                    eventAddress,
                    primaryPrice,
                    orderTime
                );

                return nftIndexP;
            }

    }

    /**
    @dev function relays mint transaction from FINANCE contract to internal function _mintGETNFT
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param eventAddress EOA address of the event (GETcustody)
    @param strikeValue price that will be paid by primary ticket buyer
    @param basePrice TODO
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function eventFinancingMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 strikeValue,
        uint256 basePrice,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
    ) public onlyRelayer returns (uint256 nftIndex) {

        // TODO NFT FIRST NEEDS TO BE FUELED
        uint256 charged = DEPOT.chargeProtocolTax(nftIndex);

        nftIndex = _mintGETNFT(
            eventAddress, // TAKE NOTE MINTING TO EVENT ADDRESS
            eventAddress,
            strikeValue,
            orderTime,
            ticketURI,
            ticketMetadata,
            true
        );

        FINANCE.registerCollaterization(
            nftIndex,
            eventAddress,
            strikeValue
        );

        emit colleterizedMint(
            nftIndex,
            charged, 
            destinationAddress,
            eventAddress,
            strikeValue,
            orderTime
        );

        return nftIndex;
    }
    
    function changeConfiguration(
        address newAddressBouncer,
        address newAddressMetadata,
        address newAddressFinance,
        address newAddressERC721,
        address newAddressEconomics,
        address newDepotAddress
    ) external onlyAdmin {
        
        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        METADATA = IMetadataStorage(newAddressMetadata);
        FINANCE = IEventFinancing(newAddressFinance);
        GET_ERC721 = IGET_ERC721(newAddressERC721);
        ECONOMICS = IEconomicsGET(newAddressEconomics);
        DEPOT = IticketFuelDepotGET(newDepotAddress);

        emit ConfigurationChanged(
            newAddressBouncer,
            newAddressMetadata,
            newAddressFinance,
            newAddressERC721,
            newAddressEconomics
        );
    }

    /**
    @dev internal getNFT minting function 
    @notice this function can be called internally, as well as externally (in case of event financing)
    @notice should only mint to EOA addresses managed by GETCustody
    @param destinationAddress EOA address that is the 'future owner' of a getNFT
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
    @param issuePrice the price the getNFT will be offered or collaterized at
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    @param setAsideNFT bool if a getNFT has been securitized 
    */
    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 issuePrice,
        uint256 orderTime,
        string memory ticketURI,
        bytes32[] memory ticketMetadata,
        bool setAsideNFT
        ) internal returns(uint256 nftIndexM) {

        nftIndexM = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        TicketData storage tdata = _ticket_data[nftIndexM];
        tdata.ticket_metadata = ticketMetadata;
        tdata.event_address = eventAddress;
        tdata.prices_sold = [issuePrice];
        tdata.set_aside = setAsideNFT;
        tdata.scanned = false;
        tdata.valid = true;
        
        emit nftMinted(
            nftIndexM,
            destinationAddress
        );

        return nftIndexM;
    }


    /** edits URI of getNFT
    @notice select getNFT by address TODO POSSIBLY REMOVE/RETIRE
    @param originAddress originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyAddress(
        address originAddress,
        string calldata newTokenURI
        ) external onlyRelayer {
            
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

            uint256 charged = DEPOT.chargeProtocolTax(nftIndex);
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                charged,
                newTokenURI
            );
        }

    /** edits metadataURI stored in the getNFT
    @dev unused function can be commented
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyIndex(
        uint256 nftIndex,
        string calldata newTokenURI
        ) external onlyRelayer {

            uint256 charged = DEPOT.chargeProtocolTax(nftIndex);
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                charged,
                newTokenURI
            );
        }


    /** transfers a getNFT from EOA to EOA
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param secondaryPrice price paid for the getNFT on the secondary market
     */
    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        uint256 charged = DEPOT.chargeProtocolTax(nftIndex);

        require(isNFTSellable(nftIndex, originAddress), "RE/SALE_ERROR");

        _ticket_data[nftIndex].prices_sold.push(secondaryPrice);
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            charged,
            destinationAddress, 
            _ticket_data[nftIndex].event_address, 
            secondaryPrice,
            orderTime
        );
    
    }

    /** scans a getNFT, validating it
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function scanNFT(
        address originAddress, 
        uint256 orderTime
        ) external onlyRelayer {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);
        
        uint256 charged = DEPOT.chargeProtocolTax(nftIndex);

        require(_ticket_data[nftIndex].valid == true, "SCAN_INVALID_TICKET");

        if (_ticket_data[nftIndex].scanned == true) {
            // The getNFT has already been scanned
            emit illegalScan(
                nftIndex,
                charged,
                orderTime
            );
        } else {
            _ticket_data[nftIndex].scanned = true;

            emit ticketScanned(
                nftIndex,
                charged,
                orderTime
            );
        }
    }

    /** invalidates a getNFT, making it unusable and untransferrable
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    */
    function invalidateAddressNFT(
        address originAddress, 
        uint256 orderTime) external onlyRelayer {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        uint256 charged = DEPOT.chargeProtocolTax(nftIndex);

        require(_ticket_data[nftIndex].valid == true, "DOUBLE_INVALIDATION");
        
        _ticket_data[nftIndex].valid = false;

        emit ticketInvalidated(
            nftIndex, 
            charged,
            originAddress,
            orderTime
        );
    } 

    /** Claims a scanned and valid NFT to an external EOA address
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param externalAddress EOA address of user that is claiming the gtNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function claimgetNFT(
        address originAddress, 
        address externalAddress,
        uint256 orderTime) external onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT

        uint256 charged = DEPOT.chargeProtocolTax(nftIndex);

        require(isNFTClaimable(nftIndex, originAddress), "CLAIM_ERROR");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        emit nftClaimed(
            nftIndex,
            charged,
            externalAddress,
            orderTime
        );

    }

    // VIEW FUNCTIONS GET PROTOCOL

    /** Returns if an getNFT can be claimed by an external EOA
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].valid == true || _ticket_data[nftIndex].scanned == true) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns if an getNFT can be resold
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTSellable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].valid == true || _ticket_data[nftIndex].scanned == false) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns getNFT metadata by current owner (EOA address)
    @param ownerAddress EOA address of the address that currently owns the getNFT
    @dev this function assumes the NFT is still owned by an address controlled by GETCustody. 
     */
    function ticketMetadataAddress(
        address ownerAddress)
      public virtual view returns (
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint256[] memory _prices_sold,
          bool _setAsideNFT,
          bool _scanned,
          bool _valid
      )
      {
          uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0); // only selects the fist getNFT
          
          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _prices_sold = tdata.prices_sold;
          _setAsideNFT = tdata.set_aside;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
      }

    function ticketMetadataIndex(
        uint256 nftIndex
    ) public view returns(
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint256[] memory _prices_sold,
          bool _setAsideNFT,
          bool _scanned,
          bool _valid
    ) 
    {
          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _prices_sold = tdata.prices_sold;
          _setAsideNFT = tdata.set_aside;
          _scanned = tdata.scanned;
          _valid = tdata.valid;
    }

    function addressToIndex(
        address ownerAddress
    ) public virtual view returns(uint256)
    {
        return GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0);
    }

    function returnStructTicket(
        uint256 nftIndex
    ) public view returns (TicketData memory)
    {
        return _ticket_data[nftIndex];
    }

}
