// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEventMetadataStorage {

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string calldata eventName, 
      string calldata shopUrl,
      string calldata imageUrl,
      bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      bytes32[] calldata extraData,
      bool isPrivate
      ) external;

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(address);

    function doesEventExist(
      address eventAddress
    ) external view returns(bool);

    event newEventRegistered(
      address indexed eventAddress, 
      string indexed eventName,
      uint256 indexed timestamp
    );

    event UnderWriterSet(
      address eventAddress,
      address underWriterAddress,
      address requester
    );

}

