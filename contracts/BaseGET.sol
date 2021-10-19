// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoundationContract.sol";
import "./interfaces/IBasketVault.sol";

contract BaseGET is FoundationContract {

    bool public onChainEconomics;
    uint256 private refactorSwapIndex;

    function __BaseGETNFT_init_unchained() internal initializer {
        onChainEconomics = false;
    }

    function __BaseGETNFT_init(
        address _configurationAddress
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
            _configurationAddress);
        __BaseGETNFT_init_unchained();
    }

    // UNSCANNED is the state the ticket assumes upon creation before it is ever scanned. Only UNSCANNED mytickets can be resold.
    // SCANNED is the state the ticket assumes when scanned; this can happen infinite number of times.
    // CLAIMABLE is the state the ticket can assume that allows it to be claimed, this happens after the finalScan
    // INVALIDATED is the state the ticket can assume when the ticket is flagged as invalid by the ticket issuer.
    // PREMINTED is the state a ticket is currently in an index contract, but it has not been sold/used as colleteral (this is essentially the 'issued for colleterization' state)
    // COLLATERALIZED ticket is at the moment colleterized / locked in the ticket event financing contract
    enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED, PREMINTED, COLLATERALIZED }

    struct TicketData {
        address eventAddress;
        bytes32[] ticketMetadata;
        uint32[2] salePrices;
        TicketStates state;
    }

    mapping (uint256 => TicketData) private _ticketData;

    event PrimarySaleMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 basePrice
    );

    event CollateralizedMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 basePrice
    );

    event SecondarySale(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 resalePrice
    );

    event TicketInvalidated(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    ); 

    event NftClaimed(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event IllegalScan(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
    
    event IllegalCheckIn(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event TicketScanned(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event CheckedIn(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event EconomicsFlipped(
        bool stateOfSwitch,
        uint256 refactorSwapIndex    
    );

    // OPERATIONAL FUNCTION

    function setOnChainSwitch(
        bool _switchState,
        uint256 _refactorSwapIndex
    ) external onlyAdmin {

        emit EconomicsFlipped(
            _switchState,
            _refactorSwapIndex
        );

        refactorSwapIndex = _refactorSwapIndex;
        onChainEconomics = _switchState;

    }

   // OPERATIONAL TICKETING FUNCTIONS //

    /**
    * @dev primary sale function, transfers or mints NFT to EOA of a primary market ticket buyer
    * @param _destinationAddress EOA address of the ticket buyer (GETcustody)
    * @param _eventAddress EOA address of the event - primary key assinged by GETcustody
    * @param _primaryPrice price paid by primary ticket buyer in the local/event currenct
    * @param _basePrice price as charged to the ticketeer in USD 
    * @param _orderTime timestamp the statechange was triggered in the system of the integrator
    * @param _ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function primarySale(
        address _destinationAddress, 
        address _eventAddress, 
        uint256 _primaryPrice,
        uint256 _basePrice,
        uint256 _orderTime,
        bytes32[] calldata _ticketMetadata
    ) external onlyRelayer {

        // Event NFT is minted for an un-colleterized/financed eventAddress -> getNFT minted to EOA account 
        uint256 _nftIndexP = _mintGETNFT( 
            _destinationAddress,
            _eventAddress,
            _primaryPrice,
            _ticketMetadata
        );

        uint256 _fueled = 0;

        if (onChainEconomics) {
            _fueled = ECONOMICS.fuelBackpackTicket(_nftIndexP, msg.sender, _basePrice);
        }

        emit PrimarySaleMint(
            _nftIndexP,
            uint64(_fueled),
            uint64(_orderTime),
            _basePrice
        );

    }

    function collateralMint(
        address _basketAddress,
        address _eventAddress, 
        uint256 _primaryPrice,
        bytes32[] calldata _ticketMetadata
    ) external onlyFactory {

        // Event NFT is created for is not colleterized, getNFT minted to index contract 
        uint256 _nftIndexC = _mintGETNFT( 
            address(BASE),
            _eventAddress,
            _primaryPrice,
            _ticketMetadata
        );

        IBasketVault(_basketAddress).depositERC721(
            address(GET_ERC721),
            _nftIndexC
        );

        emit CollateralizedMint(
            _nftIndexC,
            0,
            0,
            _primaryPrice
        );

    }

    /** transfers a getNFT from EOA to EOA
    @param _originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param _destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param _orderTime timestamp the statechange was triggered in the system of the integrator
    @param _secondaryPrice price paid for the getNFT on the secondary market
     */
    function secondaryTransfer(
        address _originAddress, 
        address _destinationAddress,
        uint256 _orderTime,
        uint256 _secondaryPrice) external onlyRelayer {

        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0);

        // require(isNFTSellable(_nftIndex, _originAddress), "RESALE_ERROR");
    
        _ticketData[_nftIndex].salePrices[1] = uint32(_secondaryPrice);

        GET_ERC721.relayerTransferFrom(
            _originAddress, 
            _destinationAddress, 
            _nftIndex
        );

        emit SecondarySale(
            _nftIndex,
            0,
            uint64(_orderTime),
            _secondaryPrice
        );
    
    }


    /** finalScan / permanent scan function
    @param _originAddress address that own the NFT
    @param _orderTime timestamp of engine of request
    @notice this function makes the nftIndex claimable
     */
    function scanNFT(
        address _originAddress,
        uint256 _orderTime
    ) external onlyRelayer {

        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0);

        require(_ticketData[_nftIndex].state != TicketStates.INVALIDATED, "SCAN_INVALIDATED");

        if(_ticketData[_nftIndex].state == TicketStates.CLAIMABLE) { // nft has been made claimable before
            
            emit IllegalScan(
                _nftIndex,
                0,
                uint64(_orderTime)
            );
        } else { // nft has never been scanned or checked
            uint256 _fueled = 0;

            if (onChainEconomics) { // transfer all the GET in the backpack to the feeCollector
                _fueled = ECONOMICS.emptyBackpackBasic(_nftIndex);
            }
        
            _ticketData[_nftIndex].state = TicketStates.CLAIMABLE;

            emit TicketScanned(
                _nftIndex,
                uint64(_fueled),
                uint64(_orderTime)
            );
        }

    }

    /** checkIn - a temporary alias for scanNFT, changes the state of a ticket to CLAIMABLE
    @param _originAddress address that own the NFT
    @param _orderTime timestamp of engine of request
    @notice this function makes the nftIndex claimable
     */
    function checkIn(
        address _originAddress,
        uint256 _orderTime
    ) external onlyRelayer {

        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0);

        require(_ticketData[_nftIndex].state != TicketStates.INVALIDATED, "CHECKIN_INVALIDATED");

        if(_ticketData[_nftIndex].state == TicketStates.CLAIMABLE) {
            // nft has been scanned before
            emit IllegalCheckIn(
                _nftIndex,
                0,
                uint64(_orderTime)
            );
        } else { // nft has never been scanned
            
            uint256 _fueled = 0;

            if (onChainEconomics) { // transfer all the GET in the backpack to the feeCollector
                _fueled = ECONOMICS.emptyBackpackBasic(_nftIndex);
            }

            _ticketData[_nftIndex].state = TicketStates.CLAIMABLE;

            emit CheckedIn(
                _nftIndex,
                uint64(_fueled),
                uint64(_orderTime)
            );
        }

    }

    /** invalidates a getNFT, making it unusable and untransferrable
    @param _originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param _orderTime timestamp the statechange was triggered in the system of the integrator
    */
    function invalidateAddressNFT(
        address _originAddress, 
        uint256 _orderTime) external onlyRelayer {
        
        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0);
        
        uint256 _fueled = 0;

        if (onChainEconomics) { // transfer all the GET in the backpack to the feeCollector
            _fueled = ECONOMICS.emptyBackpackBasic(_nftIndex);
        }

        _ticketData[_nftIndex].state = TicketStates.INVALIDATED;

        emit TicketInvalidated(
            _nftIndex, 
            uint64(_fueled),
            uint64(_orderTime)
        );
    } 

    /** Claims a scanned and valid NFT to an external EOA address
    @param _originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param _externalAddress EOA address of user that is claiming the gtNFT
    @param _orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function claimgetNFT(
        address _originAddress, 
        address _externalAddress,
        uint256 _orderTime) external onlyRelayer {

        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0); // fetch the index of the NFT

        // require(isNFTClaimable(_nftIndex, _originAddress), "CLAIM_NOT_ALLOWED");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            _originAddress, 
            _externalAddress, 
            _nftIndex
        );

        emit NftClaimed(
            _nftIndex,
            0,
            uint64(_orderTime)
        );

    }
    /**
    @dev internal getNFT minting function 
    @notice this function can be called internally, as well as externally (in case of event financing)
    @notice should only mint to EOA addresses managed by GETCustody
    @param _destinationAddress EOA address that is the 'future owner' of a getNFT
    @param _eventAddress EOA address of the event - primary key assinged by GETcustody
    @param _issuePrice the price the getNFT will be offered or collaterized at
    @param _ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function _mintGETNFT(
        address _destinationAddress, 
        address _eventAddress, 
        uint256 _issuePrice,
        bytes32[] calldata _ticketMetadata
        ) internal returns(uint256 _nftIndexM) {

        _nftIndexM = GET_ERC721.mintERC721_V3(
            _destinationAddress
        );

        TicketData storage tdata = _ticketData[_nftIndexM];
        tdata.ticketMetadata = _ticketMetadata;
        tdata.eventAddress = _eventAddress;
        tdata.salePrices[0] = uint32(_issuePrice);
        tdata.state = TicketStates.UNSCANNED;

        return _nftIndexM;
    }


    function approveBasket(
        address _basketContract
    ) external onlyAdmin {
        GET_ERC721.setApprovalForAll(_basketContract, true);
    }

    // VIEW FUNCTIONS 

    /** Returns if an getNFT can be claimed by an external EOA
    @param _nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param _originAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTClaimable(
        uint256 _nftIndex,
        
        address _originAddress
    ) public view returns(bool _claim) {

        if (_nftIndex < refactorSwapIndex) {
            return true;
        }

        else if ((_ticketData[_nftIndex].state == TicketStates.CLAIMABLE) && (GET_ERC721.ownerOf(_nftIndex) == _originAddress)) {
            return true;
        }
        else {
            return false;
        }
    }

    /** Returns if an getNFT can be resold
    @param _nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param _originAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTSellable(
        uint256 _nftIndex,
        address _originAddress
    ) public view returns(bool _sell) {

        if (_nftIndex < refactorSwapIndex) {
            return true;
         }

         else if ((_ticketData[_nftIndex].state == TicketStates.UNSCANNED) && (GET_ERC721.ownerOf(_nftIndex) == _originAddress)) {
             return true;
         } 
         else {
            return false;
         }
    }

    /** Returns getNFT metadata by current owner (EOA address)
    @param _originAddress EOA address of the address that currently owns the getNFT
    @dev this function assumes the NFT is still owned by an address controlled by GETCustody. 
     */
    function ticketMetadataAddress(
        address _originAddress)
      external view returns (
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _salePrices,
          TicketStates _state
      )
      {
          // could have a `require` clause here
          TicketData storage tdata = _ticketData[GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0)];
          _eventAddress = tdata.eventAddress;
          _ticketMetadata = tdata.ticketMetadata;
          _salePrices = tdata.salePrices;
          _state = tdata.state;
      }

    /**
    @param _nftIndex index of the ticket nft
     */ 
    function ticketMetadataIndex(
        uint256 _nftIndex
    ) external view returns(
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _salePrices,
          TicketStates _stateTicket
    ) 
    {
          TicketData storage tdata = _ticketData[_nftIndex];
          _eventAddress = tdata.eventAddress;
          _ticketMetadata = tdata.ticketMetadata;
          _salePrices = tdata.salePrices;
          _stateTicket = tdata.state;
    }

    /**
    @param _originAddress address of the owner of the getNFT
    @notice the _originAddress of an active ticket is generally held by GETCustody
     */
    function addressToIndex(
        address _originAddress
    ) external virtual view returns(uint256)
    {
        return GET_ERC721.tokenOfOwnerByIndex(_originAddress, 0);
    }

    /** returns the metadata struct of the ticket (base data)
    @param _nftIndex unique indentifier of getNFT
     */
    function returnStructTicket(
        uint256 _nftIndex
    ) external view returns (TicketData memory)
    {
        return _ticketData[_nftIndex];
    }

    function viewPrimaryPrice(
        uint256 _nftIndex
    ) external view returns (uint32) {
        return _ticketData[_nftIndex].salePrices[0];
    }

    function viewLatestResalePrice(
        uint256 _nftIndex
    ) external view returns (uint32) {
        return _ticketData[_nftIndex].salePrices[1];
    }

    function viewEventOfIndex(
        uint256 _nftIndex
    ) external view returns (address) {
        return _ticketData[_nftIndex].eventAddress;
    }

    function viewTicketMetadata(
        uint256 _nftIndex
    ) external view returns (bytes32[] memory) {
        return _ticketData[_nftIndex].ticketMetadata;
    }
    
    function viewTicketState(
        uint256 _nftIndex
    ) external view returns(uint) {
        return uint(_ticketData[_nftIndex].state);
    }
}
