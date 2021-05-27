pragma solidity ^0.6.2;
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
    IEconomicsGET public ECONOMICS;
    IticketFuelDepotGET public DEPOT;

    using SafeMathUpgradeable for uint256;
    
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    address public ticketFuelDepotAddress;
    address public emergencyAddress;

    // temporary static value of GET denominated in USD
    uint256 public priceGETUSD;

    // baseRate is the percentage amount (so 0.001) for example, 
    struct EconomicsConfig { 
        uint256 baseRate;
        bool isConfigured;
        uint256 timestampStarted; // blockheight of when the config was set
        uint256 timestampEnded; // is 0 if economics confis is still active
    }

    // mapping from relayer address to economics configs (that are active)
    mapping(address => EconomicsConfig) public allConfigs;

    // storage of fee old configs, for historical analysis
    EconomicsConfig[] public oldConfigs;

    // mapping from relayer address to GET/Fuel balance (internal fuel balance)
    mapping(address => uint256) public relayerBalance;

    // TODO check if it defaults to false for unknwon addresses.
    mapping(address => bool) public relayerRegistry;
    
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
        uint256 amountToppedUp
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
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY");
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
    
    function initialize_economics(
        address address_bouncer,
        address fueltoken_address,
        address depot_address
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            FUELTOKEN = IERC20(fueltoken_address);
            DEPOT = IticketFuelDepotGET(depot_address);
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

        // TODO add check if msg.sender is real/known/registered relayerAddress

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
            amountTopped
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
         uint256 dollarvalue
     ) public view returns(uint256) {
         require(dollarvalue > 0, "DOL_ZERO_VALUE");
         require(priceGETUSD > 0, "GET_ZERO_VALUE");
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

        return baseTicketPrice.mul(percetageCut);
    }


    /**
    @param baseTicketPrice base amount in USD of the ticket being minted
    @param percetageCut percentage 0.01, 0.03 etc that goes in the rucksack in USD value
     */
    function calcBackpackGET(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) public view returns(uint256) {

        // TODO add sanitity check for percentageCut

        uint256 _val1 = calcBackpackValue(baseTicketPrice, percetageCut);
        return calcNeededGET(_val1);
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