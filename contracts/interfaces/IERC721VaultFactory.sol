// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721VaultFactory {

  function mint(
      string memory _name, 
      string memory _symbol, 
      address _token, 
      uint256 _id, 
      uint256 _supply, 
      uint256 _listPrice, 
      uint256 _fee
      ) external returns(uint256);

  function pause() external;
  function unpause() external;

  function vaultCount() external returns(uint256);
  // function vaults() external returns(address);


  function returnVaultAddress(
    uint256 _vaultIndex
  ) external view returns(address);

}