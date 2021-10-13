// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoundationContract.sol";

contract EventMetadataStorage is FoundationContract {

    function __initialize_metadata_unchained() internal initializer {
    }

    function __initialize_metadata(
      address configuration_address
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
            configuration_address);
        __initialize_metadata_unchained();
    }

    struct EventStruct {
        address eventAddress; 
        address relayerAddress;
        address underWriterAddress;
        string eventName;
        string shopUrl;
        string imageUrl;
        bytes32[4] eventMetadata; // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
        uint256[2] eventTimes; // -> [uin256 startingTime, uint256 endingTime]
        bool setAside; // -> false = default
        bytes32[] extraData;
        bool privateEvent;
        bool created;
    }

    mapping(address => EventStruct) private allEventStructs;
    address[] private eventAddresses;  

    event NewEventRegistered(
      address indexed eventAddress,
      uint256 indexed getUsed,
      string eventName,
      uint256 indexed orderTime
    );

    event AccessControlSet(
      address indexed newAccesscontrol
    );

    event UnderWriterSet(
      address indexed eventAddress,
      address indexed underWriterAddress
    );

    event BaseConfigured(
        address baseAddress
    );

    // OPERATIONAL FUNCTIONS

    function registerEvent(
      address _eventAddress,
      address _integratorAccountPublicKeyHash,
      string memory _eventName, 
      string memory _shopUrl,
      string memory _imageUrl,
      bytes32[4] memory _eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] memory _eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool _setAside, // -> false = default
      bytes32[] memory _extraData,
      bool _isPrivate
      ) public onlyRelayer {

      address _underwriterAddress = 0x0000000000000000000000000000000000000000;

      EventStruct storage _event = allEventStructs[_eventAddress];
      _event.eventAddress = _eventAddress;
      _event.relayerAddress = _integratorAccountPublicKeyHash;
      _event.underWriterAddress = _underwriterAddress;
      _event.eventName = _eventName;
      _event.shopUrl = _shopUrl;
      _event.imageUrl = _imageUrl;
      _event.eventMetadata = _eventMeta;
      _event.eventTimes = _eventTimes;
      _event.setAside = _setAside;
      _event.extraData = _extraData;
      _event.privateEvent = _isPrivate;
      _event.created = true;

      eventAddresses.push(_eventAddress);

      emit NewEventRegistered(
        _eventAddress,
        0,
        _eventName,
        block.timestamp
      );
    }

    // VIEW FUNCTIONS

    /** returns if an event address exists 
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function doesEventExist(
      address eventAddress
    ) public view virtual returns(bool)
    {
      return allEventStructs[eventAddress].created;
    }

    /** returns all metadata of an event
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function getEventData(
      address eventAddress)
        public virtual view
        returns (
          address _relayerAddress,
          address _underWriterAddress,
          string memory _eventName,
          string memory _shopUrl,
          string memory _imageUrl,
          bytes32[4] memory _eventMeta,
          uint256[2] memory _eventTimes,
          bool _setAside,
          bytes32[] memory _extraData,
          bool _privateEvent
          )    
        {
          EventStruct storage mdata = allEventStructs[eventAddress];
          _relayerAddress = mdata.relayerAddress;
          _underWriterAddress = mdata.underWriterAddress;
          _eventName = mdata.eventName;
          _shopUrl = mdata.shopUrl;
          _imageUrl = mdata.imageUrl;
          _eventMeta = mdata.eventMetadata;
          _eventTimes = mdata.eventTimes;
          _setAside = mdata.setAside;
          _extraData = mdata.extraData;
          _privateEvent = mdata.privateEvent;
      }

    function getEventCount() public view returns(uint256) 
    {
      return eventAddresses.length;
    }

    function returnStructEvent(
        address eventAddress
    ) public view returns (EventStruct memory)
    {
        return allEventStructs[eventAddress];
    }

}