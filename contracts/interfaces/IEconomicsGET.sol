pragma solidity ^0.6.2;

interface IEconomicsGET {
    function editCoreAddresses(
        address newAddressBurn,
        address newAddressTreasury,
        address newFuelToken
    ) external;

    function chargeForStatechangeList(
        address relayerAddress,
        uint256 statechangeInt
        ) external returns (uint256[2] memory);

    function checkFeeForStatechange(
        address relayerAddress,
        uint256 statechangeInt
        ) external returns(uint256);

    function balanceOfRelayer(
        address relayerAddress
    ) external;

    function chargeForStatechange(
        address relayerAddress,
        uint256 statechangeInt
    ) external returns (bool);
    
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external;
}