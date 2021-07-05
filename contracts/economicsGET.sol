// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IGETAccessControl.sol";
import "./interfaces/IEconomicsGET.sol";
import "./interfaces/IticketFuelDepotGET.sol";
import "./interfaces/IgetNFT_ERC721.sol";

import "./utils/SafeMathUpgradeable.sol";

/** GET Protocol CORE contract
- contract that defines for different ticketeers how much is paid in GET 'gas' per statechange type
- contract/proxy will act as a prepaid bank contract.
- contract will be called using a proxy (upgradable)
- relayers are ticketeers/integrators
- contract is still WIP
 */
contract economicsGET is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IERC20 public FUELTOKEN;
    IEconomicsGET private ECONOMICS;
    IticketFuelDepotGET private DEPOT;
    IGET_ERC721 private GET_ERC721;

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;

    string public constant contractName = "economicsGET";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 private constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    function _initialize_economics(
        address address_bouncer,
        address depot_address,
        address erc721_address,
        uint64 price_getusd
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            DEPOT = IticketFuelDepotGET(depot_address);
            GET_ERC721 = IGET_ERC721(erc721_address);
            priceGETUSD = price_getusd;

            FUELTOKEN = IERC20(DEPOT.getActiveFuel());

            freeEventRate = 100;
        }

    // address that will receive all the GET on the contract
    address private emergencyAddress;

    // flat rate in usd that will be used for free events (as these have a base price of 0)
    uint256 private freeEventRate;

    // temporary static value of GET denominated in USD, used for the calculation on how much GET is required on a certain ticket/NFT
    uint256 private priceGETUSD;

    // baseRate is a percentage amount that needs to be provided in GET to fuel a complete event cycle in infinity.
    struct EconomicsConfig { 
        string ticketeerName;
        address ticketeerMasterWallet;
        uint256 baseRate; // 1000 -> 1%
        bool isConfigured;
    }

    // mapping from relayer address to economics configs (that are active)
    mapping(address => EconomicsConfig) private allConfigs;

    // mapping from relayer address to GET/Fuel balance (internal fuel balance)
    mapping(address => uint256) private relayerBalance;
    
    // EVENTS ECONOMICS GET

    event ticketeerCharged(
        address indexed ticketeerRelayer, 
        uint64 indexed chargedFee
    );

    event configChanged(
        address relayerAddress
    );

    event feeToTreasury(
        uint64 feeToTreasury,
        uint64 remainingBalance
    );

    event feeToBurn(
        uint64 feeToTreasury,
        uint64 remainingBalance
    );

    event relayerToppedUp(
        address relayerAddress,
        uint64 amountToppedUp,
        uint64 newBalanceRelayer
    );

    event allFuelPulled(
        address receivedByAddress,
        uint64 amountPulled
    );

    event coreAddressesEdit(
        address newBouncerSet,
        address newFuelSet,
        address newDepotSet,
        address newERC721
    );

    event priceGETChanged(
        uint64 newGETUSDPrice
    );

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint64 indexed amountPacked
    );

    event freeEventSet(
        uint64 newFreeEventRate
    );

    event fuelTokenSynced(
        address fuelTokenAddress
    );


    // MODIFIERS ECONOMICSGET //

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "ECONOMICS_CALLER_NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ECONOMICS_CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender), "ECONOMICS_CALLER_NOT_GOVERNANCE");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ECONOMICS_CALLER_NOT_FACTORY");
        _;
    }


    /**
     * @dev Throws if called by a relayer/ticketeer that has not been registered.
     */
    modifier onlyKnownRelayer() {
        require(
            allConfigs[msg.sender].isConfigured == true, "ECONOMICS_RELAYER_NOT_REGISTERED");
        _;
    }

    // CONFIGURATION

    function editCoreAddresses(
        address newBouncerAddress,
        address newDepotAddress,
        address newERC721Address
    ) external onlyAdmin {
        GET_BOUNCER = IGETAccessControl(newBouncerAddress);
        DEPOT = IticketFuelDepotGET(newDepotAddress);
        GET_ERC721 = IGET_ERC721(newERC721Address);

        FUELTOKEN = IERC20(DEPOT.getActiveFuel());

        emit coreAddressesEdit(
            newBouncerAddress,
            address(FUELTOKEN),
            newDepotAddress,
            newERC721Address
        );
    }

    /** set the price used by the contract to price GET in usd
    @param newGETPrice new GETUSD price used to calculate amont of GET needed in the rucksack of an NFT
     */
    function setPriceGETUSD(
        uint64 newGETPrice
    ) public onlyAdmin {
        priceGETUSD = newGETPrice;
        
        emit priceGETChanged(
            newGETPrice
        );
    }

    /**
    @param depotAddress the contract address of the depot contract that needs to be approved for token transfer
    this function allows to let the depot contract move tokens owned by the econimics address.
    @param approvalAmount ERC20 approval amount
    @notice this function will allow the depot contract to move/subtract tokens from the ticketeers that is topped up on the economics contract
     */
    function setContractAllowance(
        address depotAddress,
        uint256 approvalAmount
    ) public onlyAdmin {
        FUELTOKEN.approve(depotAddress, approvalAmount);
    }

    function setFreeEventRate(
        uint64 newFreeEventRate
    ) public onlyAdmin {
        freeEventRate = newFreeEventRate;

        emit freeEventSet(
            newFreeEventRate
        );

    }

    // technically function could be public
    function syncFuelToken() public onlyAdmin {
        FUELTOKEN = IERC20(DEPOT.getActiveFuel());

        emit fuelTokenSynced(
            address(FUELTOKEN)
        );

    }

    /** Example config
    relayerAddress: "0x123", This is the address the ticketeer is identified by.
    timestampStarted: 2311222, Blockheight start of config
    timestampEnded: none, Blockheight end of config
    treasuryL: 0.03 = 3% of the primary value in USD is put in the GET backpack
    isConfigured: bool tracking if a certain relayers GET usage contract are configured
     */


    /**
    @param relayerAddress address the ticketeer sends transcations, used for identifiaction and billing
    @param newTicketeerName the slug/brand name the ticketeer is known by publically, for easy lookup
    @param masterWallet if an relayeraddress is seeded from a 'masterRelayer' this variable is populated, otherwise it will have the burn address
    @param newBaseRate the ratio that will be used to calculate the GET backpack from the basePrice of an getNFT
     */
    function setEconomicsConfig(
        address relayerAddress,
        string memory newTicketeerName,
        address masterWallet,
        uint256 newBaseRate
    ) public onlyAdmin {

        // store config in mapping, this will overwrite previously stored configurations by the same relayerAddress
        allConfigs[relayerAddress] = EconomicsConfig(
            newTicketeerName,
            masterWallet,
            newBaseRate,
            true
        );

        emit configChanged(
            relayerAddress
        );

    }

    // OPERATIONAL FUNCTION GET ECONOMICS 

    /**
    @notice this contract can only be called by baseNFT contract via the primarySale function
    @dev it is not allowed for an getNFT ticket to not use any GET. If an event is free, a extremely low basePrice should be used. The contract handles this edgecase by replacing the basePrice of a free event with a standard rate.
    @notice will only run if a ticketeer has sufficient GET balance - otherwise will fail
    @param nftIndex unique indentifier of getNFT as 'to be minted' by baseNFT contract
    @param relayerAddress address of the ticketeer / integrator that is requesting this NFT mint, note that this is the address of the relayer that has called the baseNFT contract, this function is called by 
    @param basePrice base value in USD of the NFT that is going to be minted
    @dev the edgecase of an free event is handled by adding
     */
    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns (uint256) 
        { 
            // check if nftIndex exists
            require(GET_ERC721.isNftIndex(nftIndex), "ECONOMICS_INDEX_UNKNOWN");

            // check if relayer is registered in economics contracts
            require(checkIfRelayer(relayerAddress), "ECONOMICS_UNKNOWN_RELAYER");

            if (basePrice == 0) { // free event, replace with freeEventRate in USD
                basePrice = freeEventRate;
            }

            // check if baseprice is valid (non negative, not zero)
            require(basePrice > 0, "ECONOMICS_BASEPRICE_ZERO");

            // calculate amount of GET required for the tickets backpack starting balance
            uint256 _getamount = calcBackpackGET(
                basePrice,
                allConfigs[relayerAddress].baseRate
            );

            // check if calculated amount is higher than zero, statechanges cannot be free
            require(_getamount > 0, "FUEL_ZERO_AMOUNT");

            // check if integrator has sufficient GET to perform fueling action
            require( 
                _getamount < relayerBalance[relayerAddress],
            "GET_BALANCE_INSUFFICIENT"
            );

            // deduct the GET that will be sent to the depot from the ticketeers balance
            relayerBalance[relayerAddress] -= _getamount;

            // call depot contract to transfer the GET and register the NFT in the depot proxy
            require(
                DEPOT.fuelBackpack(
                    nftIndex,
                    _getamount
                ),
                "DEPOT_TRANSFER_FAILED");

            // return to the base contract the amount of GET added to the fuel cotract

            // emit BackpackFilled(
            //     nftIndex,
            //     uint64(_getamount)
            // );

            return _getamount;
    }
   

    // OPERATIONAL FUNCTION GET ECONOMICS 

    /**
    @notice this contract can only be called by baseNFT contract via the primarySale function
    @dev it is not allowed for an getNFT ticket to not use any GET. If an event is free, a extremely low basePrice should be used. The contract handles this edgecase by replacing the basePrice of a free event with a standard rate.
    @notice will only run if a ticketeer has sufficient GET balance - otherwise will fail
    @param nftIndex unique indentifier of getNFT as 'to be minted' by baseNFT contract
    @param relayerAddress address of the ticketeer / integrator that is requesting this NFT mint, note that this is the address of the relayer that has called the baseNFT contract, this function is called by 
    @param baseGETFee base value in USD of the NFT that is going to be minted
    @dev the edgecase of an free event is handled by adding
     */
    function fuelBackpackTicketBackfill(
        uint256 nftIndex,
        address relayerAddress,
        uint256 baseGETFee
        ) external returns (bool) 
        { 
            // check if nftIndex exists
            require(GET_ERC721.isNftIndex(nftIndex), "ECONOMICS_INDEX_UNKNOWN");

            // check if relayer is registered in economics contracts
            require(checkIfRelayer(relayerAddress), "ECONOMICS_UNKNOWN_RELAYER");

            // check if integrator has sufficient GET to perform fueling action
            require( 
                baseGETFee < relayerBalance[relayerAddress],
            "GET_BALANCE_INSUFFICIENT"
            );

            // deduct the GET that will be sent to the depot from the ticketeers balance
            relayerBalance[relayerAddress] -= baseGETFee;

            // call depot contract to transfer the GET and register the NFT in the depot proxy
            require(
                DEPOT.fuelBackpack(
                    nftIndex,
                    baseGETFee
                ),
                "DEPOT_TRANSFER_FAILED");

            // return to the base contract the amount of GET added to the fuel cotract

            // emit BackpackFilled(
            //     nftIndex,
            //     uint64(_getamount)
            // );

            return true;
    }   

    // ticketeer adds GET to their balance
    /** function that tops up the relayer account
    @dev note that relayerAddress does not have to be msg.sender
    @dev so it is possible that an address tops up an account that is not itself
    @param relayerAddress address of the ticketeer / integrator
    @param amountTopped amount of GET that is added to the balance of the integrator
     */
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) public onlyRelayer returns (uint256){

        require(amountTopped > 0, "ZERO_TOPPED_UP");

        // Check if the relayer is known
        require(checkIfRelayer(relayerAddress) == true, "TOPUP_ECON_RELAYER_UNKNOWN");

        // check if msg.sender has allowed contract to spend/send tokens on the callers behalf
        require(
            FUELTOKEN.allowance(
                relayerAddress, 
                address(this)) >= amountTopped,
            "ALLOWANCE_FAILED_TOPUPGET"
        );

        // tranfer tokens from msg.sender to this contract address (economicsGET proxy)
        require(
            FUELTOKEN.transferFrom(
                relayerAddress, 
                address(this),
                amountTopped),
            "TRANSFER_FAILED_TOPUPGET"
        );

        // add the sent tokens to the balance
        relayerBalance[relayerAddress] += amountTopped;

        emit relayerToppedUp(
            relayerAddress,
            uint64(amountTopped),
            uint64(relayerBalance[relayerAddress])
        );

        return relayerBalance[relayerAddress];
    }


  function withdrawFuel(
      address _token, 
      address _toAddress, 
      uint256 _amount) external onlyAdmin {
    IERC20(_token).transfer(_toAddress, _amount);
  }


    /**
    @param baseTicketPrice base amount in USD of the ticket being minted - scaled x1000
    @param percetageCut percentage scaled - 100 000
     */
    function calcBackpackGET(
        uint256 baseTicketPrice, 
        uint256 percetageCut 
    ) public view returns(uint256) {
        uint256 get_amount = baseTicketPrice.mul(percetageCut).div(priceGETUSD).mul(10000000000000);

        require(get_amount > 0, "CANNOT_BE_LOWER");

        return get_amount; // return in wei
    }


    /** returns the GET balance of a certain integrator address
    @param relayerAddress address of integrator/ticketeer
     */
    function balanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256) 
    {   
        require(checkIfRelayer(relayerAddress), "RELAYER_NOT_REGISTERED");
        return relayerBalance[relayerAddress];
    }

    /** returns the GET balance of the calling address
    @notice should be called by relayer
     */
    function balancerOfCaller() public view
    returns (uint64) 
        {
            return uint64(relayerBalance[msg.sender]);
        }
    
    /**  returns bool if a address is an known relayer
    @param relayerAddress address of integrator/ticketeer
     */
    function checkIfRelayer(
        address relayerAddress
    ) public view returns (bool) 
    {   
        return allConfigs[relayerAddress].isConfigured;
    }

    function getGETPrice() public view returns(uint256) {
        return priceGETUSD;
    }



}