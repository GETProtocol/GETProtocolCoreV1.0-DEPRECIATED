pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IGETAccessControl.sol";
import "./interfaces/IEconomicsGET.sol";

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

    using SafeMathUpgradeable for uint256;
    
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    address public treasuryAddress;
    address public burnAddress;
    address public emergencyAddress;

    /**
    struct defines how much GET is sent from relayer to economcs per type of contract interaction
    - treasuryFee amount of wei GET that is sent to primary
    [0 setAsideMint, 1 primarySaleMint, 2 secondarySale, 3 Scan, 4 Claim, 6 CreateEvent, 7 ModifyEvent]
    - burnFee amount of wei GET that is sent to burn adres
    [0 setAsideMint, 1 primarySaleMint, 2 secondarySale, 3 Scan, 4 Claim, 6 CreateEvent, 7 ModifyEvent]
    */
    struct EconomicsConfig {
        address relayerAddress; // address of the ticketeer/integrator
        uint256 timestampStarted; // blockheight of when the config was set
        uint256 timestampEnded; // is 0 if economics confis is still active
        uint256[] treasuryL;
        uint256[] burnL;
        bool isConfigured;
    }

    /** Example config
    relayerAddress: "0x123", This is the address the ticketeer is identified by.
    timestampStarted: 2311222, Blockheight start of config
    timestampEnded: none, Blockheight end of config
    treasuryL: [100,100,100,100]
    burnL: [100,100,100,100]
    
     */

    // mapping from relayer address to configs (that are active)
    mapping(address => EconomicsConfig) public allConfigs;

    // storage of fee old configs
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
        address requestAddress,
        address receivedByAddress,
        uint256 amountPulled
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
        address fueltoken_address
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            treasuryAddress = 0x3EaE56964B8CE1Cb52f395444c0f89577Bd6bB49;
            burnAddress = 0x3EaE56964B8CE1Cb52f395444c0f89577Bd6bB49;
            FUELTOKEN = IERC20(fueltoken_address);
        }
    

    function editCoreAddresses(
        address newAddressBurn,
        address newAddressTreasury,
        address newFuelToken
    ) external onlyAdmin {
        burnAddress = newAddressBurn;
        treasuryAddress = newAddressTreasury;
        FUELTOKEN = IERC20(newFuelToken);
    }

    function setEconomicsConfig(
        address relayerAddress,
        EconomicsConfig memory EconomicsConfigNew
    ) public onlyAdmin {

        // store config in mapping
        allConfigs[relayerAddress] = EconomicsConfigNew;

        // set the blockheight of starting block
        allConfigs[relayerAddress].timestampStarted = block.timestamp;
        allConfigs[relayerAddress].isConfigured = true;

        emit configChanged(
            relayerAddress
        );

    }

    function balanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256) 
    {
        return relayerBalance[relayerAddress];
    }

    function balancerOfCaller() public view
    returns (uint256) 
        {
            return relayerBalance[msg.sender];
        }
    
    // TOD) check if this works / can work
    function checkIfRelayer(
        address relayerAddress
    ) public view returns (bool) 
    {
        return relayerRegistry[relayerAddress];
    }
    

    /**
    @param amountToTreasury TODO
    @param amountToBurn TODO
    @param relayerA TODO
     */
    function _transferFuelTo(
        uint256 amountToTreasury,
        uint256 amountToBurn,
        address relayerA
    ) internal returns (bool) {

        uint256 _balance = relayerBalance[relayerA];
       
        require( // check if balance sufficient
            (amountToTreasury + amountToBurn) <= _balance,
        "0 chargePrimaryMint balance low"
        );

        if (amountToTreasury > 0) {
            
            // deduct from balance
            relayerBalance[relayerA] =- amountToTreasury;

            require( // transfer to treasury
            FUELTOKEN.transfer(
                treasuryAddress,
                amountToTreasury), // TODO or return false?
                "chargePrimaryMint _feeT FAIL"
            );


            emit feeToTreasury(
                amountToTreasury,
                relayerBalance[relayerA]
            );
        }

        if (amountToBurn > 0) {

            // deduct from balance 
            relayerBalance[relayerA] =- amountToBurn;

            require( // transfer to treasury
            FUELTOKEN.transfer(
                burnAddress,
                amountToBurn),
                "chargePrimaryMint _feeB FAIL"
            );


            emit feeToBurn(
                amountToBurn,
                relayerBalance[relayerA]
            );

        }
        return true;
    }


    function checkFeeForStatechange(
        address relayerAddress,
        uint256 statechangeInt
        ) external view returns (uint256) 
        {
            return allConfigs[relayerAddress].treasuryL[statechangeInt];
        }


    /**
    @param relayerAddress TODO
    @param statechangeInt TODO
     */
    function chargeForStatechangeList(
        address relayerAddress,
        uint256 statechangeInt
        ) external onlyFactory returns (uint256[2] memory) 
        { // TODO check probably external

            // how much GET needs to be sent to the treasury
            uint256 _feeT = allConfigs[relayerAddress].treasuryL[statechangeInt];
            // how much GET needs to be sent to the burn
            uint256 _feeB = allConfigs[relayerAddress].burnL[statechangeInt];

            require(
                _transferFuelTo(
                    _feeT,
                    _feeB,
                    relayerAddress),
                    "GET_FUEL_FAILED"
            );

            return [_feeT,_feeB];
    } 

    /**
    @param relayerAddress TODO
    @param statechangeInt TODO
     */
    function chargeForStatechange(
        address relayerAddress,
        uint256 statechangeInt
        ) external onlyFactory returns (bool) 
        { // TODO check probably external

            // how much GET needs to be sent to the treasury
            uint256 _feeT = allConfigs[relayerAddress].treasuryL[statechangeInt];
            // how much GET needs to be sent to the burn
            uint256 _feeB = allConfigs[relayerAddress].burnL[statechangeInt];

            bool _result = _transferFuelTo(
                _feeT,
                _feeB,
                relayerAddress
            );

            require( // TODO check if makes sense
                _result == true, 
                "fees failed poor person"
            );

            return _result;
    }       

    // ticketeer adds GET 
    /** function that tops up the relayer account
    @dev note that relayerAddress does not have to be msg.sender
    @dev so it is possible that an address tops up an account that is not itself
    @param relayerAddress TODO ADD SOME TEXT
    @param amountTopped TODO ADD SOME TEXT
    
     */
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) public onlyRelayer {

        // TODO maybe add check if msg.sender is real/known/registered

        // check if msg.sender has allowed contract to spend/send tokens
        require(
            FUELTOKEN.allowance(
                relayerAddress, 
                address(this)) >= amountTopped,
            "topUpGet - ALLOWANCE FAILED - ALLOW CONTRACT FIRST!"
        );

        // tranfer tokens from msg.sender to contract
        require(
            FUELTOKEN.transferFrom(
                relayerAddress, 
                address(this),
                amountTopped),
            "topUpGet - TRANSFERFROM STABLES FAILED"
        );


        // add the sent tokens to the balance
        relayerBalance[relayerAddress] = amountTopped;

        emit relayerToppedUp(
            relayerAddress,
            amountTopped
        );
    }

    // emergency function pulling all GET to admin address
    function emergencyPullGET() 
        external onlyGovernance {

        // fetch GET balance of this contract
        uint256 _balanceAll = FUELTOKEN.balanceOf(address(this));

        require(
            address(emergencyAddress) != address(0),
            "emergencyAddress not set"
        );

        emit allFuelPulled(
            msg.sender,
            emergencyAddress,
            _balanceAll
        );

    }

    /** Returns the amount of GET on the balance of the 
    @param relayerAddress TODO 
     */
    function fuelBalanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256 _balance) 
    {
        // TODO add check if relayer exists
        _balance = relayerBalance[relayerAddress];
    }

}