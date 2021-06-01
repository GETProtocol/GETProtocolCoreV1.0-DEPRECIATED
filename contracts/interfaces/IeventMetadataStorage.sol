// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IMetadataStorage {

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string calldata eventName, 
      string calldata shopUrl,
      string calldata imageUrl,
      bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      // bytes[] memory extraData
      bytes32[] calldata extraData,
      bool isPrivate
      ) external;


    function isInventoryUnderwritten(
        address eventAddress
    ) external view returns(bool);

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

    event AccessControlSet(
      address requester,
      address new_accesscontrol
    );

    event UnderWriterSet(
      address eventAddress,
      address underWriterAddress,
      address requester
    );

}

