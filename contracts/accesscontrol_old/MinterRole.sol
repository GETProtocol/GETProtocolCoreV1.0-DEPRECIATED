pragma solidity ^0.6.0;

import "./Roles.sol";
import "./Context.sol";

/** 
* @title Contract that controls what addresses are able to mint new NFTs
* @notice  Only whitelisted minters can add new minters.
* @notice The first whitelisted minter is the deploying address of the contract.
 */
contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed minterAddress);
    event MinterRemoved(address indexed minterAddress);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address minterAddress) public view returns (bool) {
        return _minters.has(minterAddress);
    }

    function addMinter(address minterAddress) public onlyMinter {
        _addMinter(minterAddress);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address minterAddress) internal {
        _minters.add(minterAddress);
        emit MinterAdded(minterAddress);
    }

    function _removeMinter(address minterAddress) internal {
        _minters.remove(minterAddress);
        emit MinterRemoved(minterAddress);
    }
}