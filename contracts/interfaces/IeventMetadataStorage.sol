pragma solidity ^0.6.2;

interface IMetadataStorage {

    function isInventoryUnderwritten(
        address eventAddress
    ) external view returns(
        bool isUnderwritten
    );

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(
        address underwriterAddress
    );

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

