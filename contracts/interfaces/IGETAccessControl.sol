pragma solidity ^0.6.2;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}