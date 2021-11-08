// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoundationContract.sol";

contract BaseGET1155 is FoundationContract {
    function __BaseGETNFT_init_unchained() internal initializer {}

    function __BaseGETNFT_init(address configuration_address) public initializer {
        __Context_init();
        __FoundationContract_init(configuration_address);
        __BaseGETNFT_init_unchained();
    }

    // UNSCANNED is the state the ticket assumes upon creation before it is ever scanned. Only UNSCANNED mytickets can be resold.
    // SCANNED is the state the ticket assumes when scanned; this can happen infinite number of times.
    // CLAIMABLE is the state the ticket can assume that allows it to be claimed, this happens after the finalScan
    // INVALIDATED is the state the ticket can assume when the ticket is flagged as invalid by the ticket issuer.
    // PREMINTED is the state a ticket is currently in an index contract, but it has not been sold/used as colleteral (this is essentially the 'issued for colleterization' state)
    // COLLATERALIZED ticket is at the moment colleterized / locked in the ticket event financing contract
    enum TicketStates {
        UNSCANNED,
        SCANNED,
        CLAIMABLE,
        INVALIDATED,
        PREMINTED,
        COLLATERALIZED,
        CLAIMED
    }

    struct TicketData {
        address eventAddress;
        bytes32[] ticketMetadata;
        uint32[2] salePrices;
        TicketStates state;
    }

    mapping(uint256 => TicketData) private _ticket_data;

    event PrimarySaleMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 basePrice
    );

    event PrimaryBatchMint(
        uint256[] indexed ids,
        uint64 indexed getUsed,
        uint64 orderTime,
        uint256[] indexed basePrices
    );

    event SecondarySale(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint256 resalePrice,
        uint64 indexed orderTime
    );

    event TicketInvalidated(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event NftClaimed(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime);

    event NftTokenURIEdited(uint256 indexed nftIndex, uint64 indexed getUsed, string netTokenURI);

    event IllegalScan(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime);

    event TicketScanned(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime);

    event NFTCheckedIn(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime);

    // OPERATIONAL TICKETING FUNCTIONS //

    /**
     * @dev primary sale function, transfers or mints NFT to EOA of a primary market ticket buyer
     * @param eventAddress EOA address of the event and the address the ticket is minted to - primary key assinged by GETcustody
     * @param id uinque NFT identifier
     * @param primaryPrice price paid by primary ticket buyer in the local/event currenct
     * @param basePrice price as charged to the ticketeer in USD
     * @param orderTime timestamp the statechange was triggered in the system of the integrator
     * @param data an arbitrary data to be stored on-chain
     * @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list
     */
    function primarySale(
        address eventAddress,
        uint256 id,
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        bytes memory data,
        bytes32[] memory ticketMetadata
    ) public onlyRelayer {
        // Event NFT is minted for an un-colleterized/financed eventAddress -> getNFT minted to EOA account
        _mintGETNFT(eventAddress, id, primaryPrice, data, ticketMetadata);

        uint256 _fueled = ECONOMICS.fuelBackpackTicket(msg.sender, basePrice);

        emit PrimarySaleMint(id, uint64(_fueled), uint64(orderTime), basePrice);
    }

    function primaryBatchSale(
        address eventAddress,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory basePrices,
        uint256 orderTime,
        bytes memory meta
    ) public onlyRelayer {
        require(
            (ids.length == basePrices.length) && (ids.length == amounts.length),
            "BaseGET: Invalid call to primaryBatchSale"
        );

        GET_ERC1155.mintBatch(eventAddress, ids, amounts, meta);

        uint256 _fueled = ECONOMICS.fuelBatchBackpackTickets(ids, msg.sender, basePrices);

        emit PrimaryBatchMint(ids, uint64(_fueled), uint64(orderTime), basePrices);
    }

    // TODO: Make this 1155 compatible
    function collateralMint(
        address destinationAddress, // index contract address
        address eventAddress,
        uint256 primaryPrice,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
    ) external onlyFactory returns (uint256) {
        // Event NFT is created for is not colleterized, getNFT minted to index contract
        // uint256 nftIndexC = _mintGETNFT(
        //     destinationAddress,
        //     eventAddress,
        //     primaryPrice,
        //     ticketURI,
        //     ticketMetadata
        // );
        // return nftIndexC;
    }

    /** transfers a getNFT from EOA to EOA
    @param id NFT index
    @param eventAddress EOA address of GETCustody that is the event the getNFT was issued for
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param primaryPrice price paid for the getNFT during the primary sale
    @param secondaryPrice price paid for the getNFT on the secondary market
     */
    function secondaryTransfer(
        uint256 id,
        address eventAddress,
        uint256 orderTime,
        uint256 primaryPrice,
        uint256 secondaryPrice
    ) public onlyRelayer {
        if (_ticket_data[id].eventAddress == address(0)) {
            TicketData storage tdata = _ticket_data[id];
            tdata.eventAddress = eventAddress;
            tdata.salePrices[0] = uint32(primaryPrice);
            tdata.salePrices[1] = uint32(secondaryPrice);
            tdata.state = TicketStates.UNSCANNED;
        } else {
            require(_ticket_data[id].state == TicketStates.UNSCANNED, "RE/SALE_ERROR");
        }

        emit SecondarySale(id, 0, secondaryPrice, uint64(orderTime));
    }

    /** finalScan / permanent scan function
    @param id NFT index
    @param orderTime timestamp of engine of request
     */
    function scanNFT(
        uint256 id,
        uint256 orderTime,
        address eventAddress
    ) public onlyRelayer {
        if (_ticket_data[id].eventAddress == address(0)) {
            TicketData storage tdata = _ticket_data[id];
            tdata.eventAddress = eventAddress;
            tdata.state = TicketStates.CLAIMABLE;

            // transfer all the GET in the backpack to the feeCollector
            uint256 _fueled = ECONOMICS.emptyBackpackBasic(msg.sender);

            _ticket_data[id].state = TicketStates.CLAIMABLE;

            emit TicketScanned(id, uint64(_fueled), uint64(orderTime));
        } else {
            require(_ticket_data[id].state != TicketStates.INVALIDATED, "SCAN_INVALIDATED");

            if (_ticket_data[id].state == TicketStates.CLAIMABLE) {
                // nft has been scanned before
                emit IllegalScan(id, 0, uint64(orderTime));
            } else {
                // nft has never been scanned
                // transfer all the GET in the backpack to the feeCollector
                uint256 _fueled = ECONOMICS.emptyBackpackBasic(msg.sender);

                _ticket_data[id].state = TicketStates.CLAIMABLE;

                emit TicketScanned(id, uint64(_fueled), uint64(orderTime));
            }
        }
    }

    /** invalidates a getNFT, making it unusable and untransferrable
    @param id unique ticket ID
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    */
    function invalidateNFT(
        uint256 id,
        uint256 orderTime,
        address eventAddress
    ) public onlyRelayer {
        if (_ticket_data[id].eventAddress == address(0)) {
            TicketData storage tdata = _ticket_data[id];
            tdata.eventAddress = eventAddress;
            tdata.state = TicketStates.INVALIDATED;
        } else {
            require(_ticket_data[id].state != TicketStates.INVALIDATED, "DOUBLE_INVALIDATION");

            _ticket_data[id].state = TicketStates.INVALIDATED;
        }

        emit TicketInvalidated(id, 0, uint64(orderTime));
    }

    /** Claims a scanned and valid NFT to an external EOA address
    @param id unique ticket ID
    @param eventAddress EOA address of GETCustody that is the known owner of the getNFT
    @param externalAddress EOA address of user that is claiming the gtNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function claimGetNFT(
        uint256 id,
        address eventAddress,
        address externalAddress,
        uint256 orderTime,
        bytes memory data
    ) public onlyRelayer {
        TicketData storage tdata = _ticket_data[id];

        if (tdata.eventAddress == address(0)) {
            tdata.eventAddress = eventAddress;
            tdata.state = TicketStates.CLAIMED;
        } else {
            require(tdata.state == TicketStates.CLAIMABLE, "CLAIM_ERROR");
            tdata.state = TicketStates.CLAIMED;
        }
        /// Transfer the NFT to destinationAddress
        GET_ERC1155.relayerTransferFrom(id, eventAddress, externalAddress, data);
        emit NftClaimed(id, 0, uint64(orderTime));
    }

    /**
    @dev internal getNFT minting function 
    @notice this function can be called internally, as well as externally (in case of event financing)
    @notice should only mint to EOA addresses managed by GETCustody
    @param eventAddress EOA address of the event - primary key assinged by GETcustody    
    * @param id uinque NFT identifier
    @param issuePrice the price the getNFT will be offered or collaterized at
    @param data arbitrary data to be stored on-chain
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function _mintGETNFT(
        address eventAddress,
        uint256 id,
        uint256 issuePrice,
        bytes memory data,
        bytes32[] memory ticketMetadata
    ) internal returns (uint256) {
        GET_ERC1155.mint(eventAddress, id, data);

        TicketData storage tdata = _ticket_data[id];
        tdata.ticketMetadata = ticketMetadata;
        tdata.eventAddress = eventAddress;
        tdata.salePrices[0] = uint32(issuePrice);
        tdata.state = TicketStates.UNSCANNED;
        return id;
    }

    /** edits metadataURI stored in the getNFT
    @dev unused function can be commented
    @param id uint256 unique identifier of getNFT assigned by contract at mint
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyIndex(uint256 id, string memory newTokenURI) public onlyRelayer {
        emit NftTokenURIEdited(id, 0, newTokenURI);
    }

    // VIEW FUNCTIONS

    /** Returns if an getNFT can be claimed by an external EOA
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param eventAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTClaimable(uint256 nftIndex, address eventAddress) public view returns (bool) {
        if (_ticket_data[nftIndex].state == TicketStates.CLAIMABLE) {
            return true;
        } else {
            return false;
        }
    }

    /** Returns if an getNFT can be resold
    @param id uint256 unique identifier of getNFT assigned by contract at mint
    */
    function isNFTSellable(uint256 id) public view returns (bool) {
        if (_ticket_data[id].state == TicketStates.UNSCANNED) {
            return true;
        }
        return false;
    }

    /**
    @param nftIndex index of the nft
    TODO change this function as to work with the new TicketData struct
     */
    function ticketMetadataIndex(uint256 nftIndex)
        public
        view
        returns (
            address _eventAddress,
            bytes32[] memory _ticketMetadata,
            uint32[2] memory _salePrices,
            TicketStates _state
        )
    {
        TicketData storage tdata = _ticket_data[nftIndex];
        _eventAddress = tdata.eventAddress;
        _ticketMetadata = tdata.ticketMetadata;
        _salePrices = tdata.salePrices;
        _state = tdata.state;
    }

    /**
    @param ownerAddress address of the owner of the getNFT
    @notice the ownerAddress of an active ticket is generally held by GETCustody
     */

    /** returns the metadata struct of the ticket (base data)
    @param nftIndex unique indentifier of getNFT
     */
    function returnStructTicket(uint256 nftIndex) public view returns (TicketData memory) {
        return _ticket_data[nftIndex];
    }

    function viewPrimaryPrice(uint256 nftIndex) public view returns (uint32) {
        return _ticket_data[nftIndex].salePrices[0];
    }

    function viewLatestResalePrice(uint256 nftIndex) public view returns (uint32) {
        return _ticket_data[nftIndex].salePrices[1];
    }

    function viewEventOfIndex(uint256 nftIndex) public view returns (address) {
        return _ticket_data[nftIndex].eventAddress;
    }

    function viewTicketMetadata(uint256 nftIndex) public view returns (bytes32[] memory) {
        return _ticket_data[nftIndex].ticketMetadata;
    }

    function viewTicketState(uint256 nftIndex) public view returns (uint256) {
        return uint256(_ticket_data[nftIndex].state);
    }
}
