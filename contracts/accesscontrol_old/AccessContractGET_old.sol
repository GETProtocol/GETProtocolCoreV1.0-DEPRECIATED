pragma solidity ^0.6.0;

import "./MinterRole.sol";
import "./RelayerRole.sol";

contract AccessContractGET is MinterRole, RelayerRole { 
    constructor() public MinterRole() RelayerRole()  { }

}