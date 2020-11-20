pragma solidity ^0.6.0;

import "./interfaces/IERCMetaDataIssuersEvents.sol";
import "./interfaces/IERCERC721_TICKETING_V3.sol";


/** 
* @dev registery contract aggregating the z
*/
contract getNFTExplorerBase {

    MetaDataIssuersEvents public METADATA_CONTRACT;
    getNFTFactory public FACTORY;
}

