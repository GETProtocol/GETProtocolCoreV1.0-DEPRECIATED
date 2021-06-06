// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}