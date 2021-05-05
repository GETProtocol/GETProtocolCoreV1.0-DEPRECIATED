pragma solidity ^0.6.2;

interface IEconomicsGET {
    function editCoreAddresses(
        address _address_burn_new,
        address _address_treasury_new
    ) external;
    function chargeForStatechange(
        address relayerAddress,
        uint256 statechangeInt
    ) external returns (bool);
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external returns (bool);
}