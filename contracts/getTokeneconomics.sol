pragma solidity ^0.6.2;

import "./utils/Initializable.sol";

contract IGETAccessControlUpgradeable {

    function hasRole(bytes32, address) public view returns (bool) {}

}

import "./interfaces/IERC20.sol";

contract getTokeneconomics is Initializable {
    IGETAccessControlUpgradeable public gAC;
    IERC20 public FUELTOKEN;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    address public GETcollector;
    uint256 public mintGETfee; 
    uint256 public transferGETfee;
    uint256 public eventGETfee;
    uint256 public claimNFTfee;
    
    event ticketeerCharged(address indexed ticketeerRelayer, uint256 indexed chargedFee);

    function initialize_economics(address _address_gAC, address _get_fuel_address) public initializer {
        gAC = IGETAccessControlUpgradeable(_address_gAC);
        FUELTOKEN = IERC20(_get_fuel_address);
        GETcollector = 0x6058233f589DBE86f38BC64E1a77Cf16cf3c6c7e;
        mintGETfee = 10000;
        transferGETfee = 10000;
        eventGETfee = 10000;
        claimNFTfee = 10000;
        }

    function chargePrimaryMint(address relayer_address) public {
        require(gAC.hasRole(RELAYER_ROLE, msg.sender), "chargePrimaryMint: must have factory role to charge");
        uint256 _balance = FUELTOKEN.balanceOf(msg.sender);
        require(_balance > mintGETfee, "getNFT factory has too little GET - Please top-up GET to continue use.");
        FUELTOKEN.transfer(GETcollector, mintGETfee);

    }
}