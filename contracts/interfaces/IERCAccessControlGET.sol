pragma solidity ^0.6.0;

interface AccessContractGET {
    function hasRole(bytes32 role, address account) external view returns (bool);
}