// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IGETAccessControl.sol";
import "./interfaces/IEconomicsGET.sol";
import "./interfaces/IticketFuelDepotGET.sol";

import "./utils/SafeMathUpgradeable.sol";

/** GET Protocol CORE contract
- contract that defines for different ticketeers how much is paid in GET 'gas' per statechange type
- contract/proxy will act as a prepaid bank contract.
- contract will be called using a proxy (upgradable)
- relayers are ticketeers/integrators
- contract is still WIP
 */
contract economicsGET is Initializable {
    IGETAccessControl public GET_BOUNCER;
    IERC20 public FUELTOKEN;
    IEconomicsGET private ECONOMICS;
    IticketFuelDepotGET private DEPOT;

    using SafeMathUpgradeable for uint256;

    string public constant contractName = "economicsGET";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 private constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    function _initialize_economics(
        address address_bouncer,
        address fueltoken_address,
        address depot_address,
        uint256 price_getusd
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            FUELTOKEN = IERC20(fueltoken_address);
            DEPOT = IticketFuelDepotGET(depot_address);
            priceGETUSD = price_getusd;
        }

    /**
    @param depotAddress the contract address of the depot contract that needs to be approved for token transfer
    this function allows to let the depot contract move tokens owned by the econimics address. 
    @notice this function will allow the depot contract to move/subtract tokens from the ticketeers that is topped up on the economics contract
     */
    function setContractAllowance(
        address depotAddress,
        uint256 approvalAmount
    ) public onlyAdmin {
        FUELTOKEN.approve(depotAddress, approvalAmount);
    }

    address private ticketFuelDepotAddress;
    address private emergencyAddress;

    // temporary static value of GET denominated in USD
    uint256 private priceGETUSD;

    // baseRate is the percentage amount (so 0.001) for example, 
    struct EconomicsConfig { 
        uint256 baseRate;
        bool isConfigured;
        uint256 timestampStarted; // blockheight of when the config was set
        uint256 timestampEnded; // is 0 if economics confis is still active
    }

    // mapping from relayer address to economics configs (that are active)
    mapping(address => EconomicsConfig) private allConfigs;

    // storage of fee old configs, for historical analysis
    EconomicsConfig[] private oldConfigs;

    // mapping from relayer address to GET/Fuel balance (internal fuel balance)
    mapping(address => uint256) private relayerBalance;

    // TODO check if it defaults to false for unknwon addresses.
    mapping(address => bool) private relayerRegistry;
    
    event ticketeerCharged(
        address indexed ticketeerRelayer, 
        uint256 indexed chargedFee
    );

    event configChanged(
        address relayerAddress
    );

    event feeToTreasury(
        uint256 feeToTreasury,
        uint256 remainingBalance
    );

    event feeToBurn(
        uint256 feeToTreasury,
        uint256 remainingBalance
    );

    event relayerToppedUp(
        address relayerAddress,
        uint256 amountToppedUp,
        uint256 newBalanceRelayer
    );

    event allFuelPulled(
        address receivedByAddress,
        uint256 amountPulled
    );

    event coreAddressesEdit(
        address newBouncerSet,
        address newFuelSet,
        address newDepotSet
    );

    event priceGETChanged(
        uint256 newGETUSDPrice
    );

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint256 indexed amountPacked
    );

    // MODIFIERS ECONOMICSGET //

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender), "CALLER_NOT_GOVERNANCE");
        _;
    }


    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY EC");
        _;
    }


    /**
     * @dev Throws if called by a relayer/ticketeer that has not been registered.
     */
    modifier onlyKnownRelayer() {
        require(
            relayerRegistry[msg.sender] == true, "RELAYER_NOT_REGISTERED");
        _;
    }


    function editCoreAddresses(
        address newBouncerAddress,
        address newFuelAddress,
        address newDepotAddress
    ) external onlyAdmin {
        GET_BOUNCER = IGETAccessControl(newBouncerAddress);
        FUELTOKEN = IERC20(newFuelAddress);
        DEPOT = IticketFuelDepotGET(newDepotAddress);

        emit coreAddressesEdit(
            newBouncerAddress,
            newFuelAddress,
            newDepotAddress
        );
    }


    /** Example config
    relayerAddress: "0x123", This is the address the ticketeer is identified by.
    timestampStarted: 2311222, Blockheight start of config
    timestampEnded: none, Blockheight end of config
    treasuryL: 0.03 = 3% of the primary value in USD is put in the GET backpack
    isConfigured: bool tracking if a certain relayers GET usage contract are configured
     */
    function setEconomicsConfig(
        address relayerAddress,
        EconomicsConfig memory EconomicsConfigNew
    ) public onlyAdmin {

        // store config in mapping
        allConfigs[relayerAddress] = EconomicsConfigNew;

        // set the blockheight of starting block
        allConfigs[relayerAddress].timestampStarted = block.timestamp;
        
        // mark storage slot as being occupied
        allConfigs[relayerAddress].isConfigured = true;

        emit configChanged(
            relayerAddress
        );

    }

    /**
    @notice this contract can only be called by baseNFT contract via the primarySale funciton
    @notice will only run if a ticketeer has sufficient GET balance - otherwise will fail
    @param nftIndex unique indentifier of getNFT as 'to be minted' by baseNFT contract
    @param relayerAddress address of the ticketeer / integrator that is requesting this NFT mint
    @param basePrice base value in USD of the NFT that is going to be offered
     */
    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external onlyFactory returns (uint256) 
        { 

            // calculate amount of GET required for backpack
            uint256 _getamount = calcBackpackGET(
                basePrice,
                allConfigs[relayerAddress].baseRate
            );

            require(_getamount > 0, "FUEL_ZERO_AMOUNT");

            // check if integrator has sufficient GET for action
            require( 
                _getamount <= relayerBalance[relayerAddress],
            "GET_BALANCE_LOW"
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

            // return to the base contract the amount of GET used

            emit BackpackFilled(
                nftIndex,
                _getamount
            );

            return _getamount;
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
    ) public onlyRelayer {

        require(amountTopped > 0, "ZERO_TOPPED_UP");
        // require(relayerRegistry[relayerAddress], "UNKNOWN_RELAYER");

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
            amountTopped,
            relayerBalance[relayerAddress]
        );
    }


    /** set the price used by the contract to price GET in usd
    @param newGETPrice new GETUSD price used to calculate amont of GET needed in the rucksack of an NFT
     */
    function setPriceGETUSD(
        uint256 newGETPrice
    ) public onlyAdmin {
        priceGETUSD = newGETPrice;
        
        emit priceGETChanged(
            newGETPrice
        );
    }

    /** calculates the amount of GET required in a backpack
    @notice in dollarvalue the total USD value of the ticket needs to be passed
    @notice this function uses the contracts global priceGETUSD value to determine the price
    @param dollarvalue amount of USD that needs to be in the rucksack
     */
     function calcNeededGET(
         uint256 dollarvalue // 500 -> $5.00/GET
     ) public view returns(uint256) {
         require(dollarvalue < 0, "DOL_ZERO_VALUE");
         require(priceGETUSD < 0, "GET_ZERO_VALUE");
         return dollarvalue.div(priceGETUSD);
     }


    /**
    @param baseTicketPrice base amount in USD of the ticket being minted
    @param percetageCut percentage 0.01, 0.03 etc that goes in the rucksack in USD value
     */
    function calcBackpackValue(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) public view returns(uint256) {

        // TODO add sanitity check for percentageCut

        return baseTicketPrice.mul(percetageCut).div(10000);
    }

    /**
    @param baseTicketPrice base amount in USD of the ticket being minted
    @param percetageCut percentage 1 = 0.01 10 = 0.1 100 = 1 etc that goes in the rucksack in USD value
     */
    function calcBackpackGET(
        uint256 baseTicketPrice, // 10 000 dollar cents ($100) magnified: x100
        uint256 percetageCut // 200 (2% or 0.02) maginified: x10 000
    ) public view returns(uint256) {

        uint256 _val1 = baseTicketPrice.mul(percetageCut).div(10);
        uint256 _val2 = _val1.div(priceGETUSD);

        uint256 _val3 = _val2.mul(1000000000000000);

        return _val3; // 200 ($2)
    }


    /** Returns the amount of GET on the balance of the 
    @param relayerAddress address of the ticketeer / integrator
     */
    function fuelBalanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256) 
    {
        // TODO add check if relayer exists
       return relayerBalance[relayerAddress];
    }


    /** returns the GET balance of a certain integrator address
    @param relayerAddress address of integrator/ticketeer
     */
    function balanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256) 
    {
        return relayerBalance[relayerAddress];
    }

    /** returns the GET balance of the calling address
    @notice should be called by relayer
     */
    function balancerOfCaller() public view
    returns (uint256) 
        {
            return relayerBalance[msg.sender];
        }
    
    /**  returns bool if a address is an known relayer
    @param relayerAddress address of integrator/ticketeer
     */
    function checkIfRelayer(
        address relayerAddress
    ) public view returns (bool) 
    {
        return relayerRegistry[relayerAddress];
    }


}