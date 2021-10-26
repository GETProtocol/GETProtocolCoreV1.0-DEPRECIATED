
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleGET {
    function update() external;
    function consult(address token, uint amountIn) external view returns (uint amountOut);

    function blockTimestampLast() external view returns (uint32);
    function PERIOD() external view returns (uint);

}