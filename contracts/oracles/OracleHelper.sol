// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracleGET.sol";
import "../FoundationContract.sol";

contract OracleHelper is FoundationContract {

    // addresses of the oracles
    IOracleGET public oracleGETETH; 
    IOracleGET public oracleUSDCETH;

    address public addressGET; // address of the GET token on POLYGON!
    address public addressUSDC; // address of the USDC token on POLYGON!
    address public addressETH; // address of wrapped ETH on POLYGON

    // uint32  public stampPreviousUpdate;
    uint32 public lastEconomicsUpdate;

    // this is the dollar value of 1 GET in USDC(6 decimals) as it was last stored in the economics contract
    // note USDC only has 6 decimals, so if you want to calculate how much dollars it is you need to divide by 1_000_000
    uint256 public priceGETUSDLastEconomics;

    uint256 public priceOracleGETETH;
    uint256 public priceOracleUSDCETH;

    mapping(address => bool) public isOracleUpdater;

    event PriceGETUSDUpdated(
        uint256 priceGETUpdated
    );

    event ThereWasAnAttempt(
        address _tryhardAddress
    );

    function __OracleHelper_init_unchained(
        address _addressGETETHPool,
        address _addressUSDCETHPool,
        address _addressGET,
        address _addressUSDC,
        address _addressETH
    ) internal initializer {
        oracleGETETH = IOracleGET(_addressGETETHPool);
        oracleUSDCETH = IOracleGET(_addressUSDCETHPool);
        addressGET = _addressGET;
        addressUSDC = _addressUSDC;
        addressETH = _addressETH;
    }

    function __OracleHelper_init(
        address _configurationAddress,
        address _addressGETETHPool,
        address _addressUSDCETHPool,
        address _addressGET,
        address _addressUSDC,
        address _addressETH
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
        _configurationAddress);
        __OracleHelper_init_unchained(
            _addressGETETHPool,
            _addressUSDCETHPool,
            _addressGET,
            _addressUSDC,
            _addressETH
        );
    }

    // constructor(
    //     address _addressGETETHPool,
    //     address _addressUSDCETHPool,
    //     address _addressGET,
    //     address _addressUSDC,
    //     address _addressETH
    // ) public {
    //     oracleGETETH = IOracleGET(_addressGETETHPool);
    //     oracleUSDCETH = IOracleGET(_addressUSDCETHPool);
    //     addressGET = _addressGET;
    //     addressUSDC = _addressUSDC;
    //     addressETH = _addressETH;
    // }

    function updateEconomicsPrice() external {
        
        uint32 _currentBlock = currentBlockTimestamp();

        uint256 _priceGET = _updateOracles(_currentBlock);

        if (_priceGET != priceGETUSDLastEconomics) {
            // update the economics contract
            // ECONOMICS.setGETUSDPrice(_priceGET);

            // mint a reward NFT to the updater
            // _mintRewardNFT();

            isOracleUpdater[msg.sender] = true;

            emit PriceGETUSDUpdated(
                _priceGET
            );
        
        } else {

            emit ThereWasAnAttempt(
                msg.sender
            );
        }

    }


    function _updateOracles(
        uint32 _currentBlock
    ) internal returns (uint256) {

        uint256 _priceUSDCETH;
        uint256 _priceGETETH;

        if (isGETETHOracleFresh(_currentBlock) == false) {
            oracleGETETH.update(); // update the GETETH oracle

            _priceGETETH = oracleGETETH.consult(
                addressGET,
                1_00000_00000_00000_000 /** 1e18 = 1 unit of GET */
            );
        } else {
            _priceGETETH = priceOracleGETETH;
        }


        if (isUSDCETHOracleFresh(_currentBlock) == false) {
            oracleUSDCETH.update(); // update the USDCETH oracle

            // calculate how much units of USDC you receive when selling 1 full ETH in 
            _priceUSDCETH = oracleUSDCETH.consult(
                addressETH,
                1_00000_00000_00000_000 /** 1e18 = 1 unit of ETH */
            );
        } else {
            _priceUSDCETH = priceOracleUSDCETH;
        }

        // note USDC has 6 decimals, so divide by 1e6 for USD amount
        priceGETUSDLastEconomics = (_priceGETETH * _priceUSDCETH) / 1_000_000;

        return priceGETUSDLastEconomics;

    }    


    // checks how long ago the GETETH oracle was updated 
    function isGETETHOracleFresh(
        uint32 _currentBlock
    ) public view returns (bool) {
        uint32 _updatedLast = oracleGETETH.blockTimestampLast();
        uint32 _diff = _currentBlock - _updatedLast;
        uint _period = oracleGETETH.PERIOD();

        if (_diff >= _period) { // it has been more than 24 hours since the last update of the oracle
            return false;
        }
        else {
            return true;
        }
    }

    // checks how long ago the GETETH oracle was updated 
    function isUSDCETHOracleFresh(
        uint32 _currentBlock
    ) public view returns (bool) {
        uint32 _updatedLast = oracleUSDCETH.blockTimestampLast();
        uint32 _diff = _currentBlock - _updatedLast;
        uint _period = oracleUSDCETH.PERIOD();

        if (_diff >= _period) { // it has been more than 24 hours since the last update of the oracle
            return false;
        }
        else {
            return true;
        }
    }


    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

}