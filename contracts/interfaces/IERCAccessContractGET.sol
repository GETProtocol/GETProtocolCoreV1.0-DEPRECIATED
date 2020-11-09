pragma solidity ^0.6.0;

interface IERCAccessContractGET is AccessContractGET {
    function isMinter(address minterAddress) external view returns (bool);

}
