// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoundationContract.sol";

contract GetEventFinancing is FoundationContract {

    function __initialize_event_financing_unchained() internal initializer {}

    function __initialize_event_financing(
        address configuration_address
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
            configuration_address);
        __initialize_event_financing_unchained();
    }
}
