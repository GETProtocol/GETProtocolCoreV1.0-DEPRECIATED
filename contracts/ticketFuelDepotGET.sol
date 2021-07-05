// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IGETAccessControl.sol";
import "./interfaces/IEconomicsGET.sol";
import "./utils/SafeMathUpgradeable.sol";
import "./interfaces/IgetNFT_ERC721.sol";

import "./utils/EnumerableSetUpgradeable.sol";
import "./utils/EnumerableMapUpgradeable.sol";

contract ticketFuelDepot is Initializable, ContextUpgradeable {
    IGETAccessControl private GET_BOUNCER;
    IERC20 public ACTIVE_FUELTOKEN;
    IEconomicsGET private ECONOMICS;
    IGET_ERC721 private GET_ERC721;

    bool public isFuelLocked;

    using SafeMathUpgradeable for uint256;

    string public constant contractName = "ticketFuelDepot";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 private constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

  function _initialize_depot(
        address address_bouncer,
        address fueltoken_address,
        address new_collectAddress,
        address address_erc721,
        uint64 taxrate_global // %3 0 0.03 - scaled: x100 000   - uint64
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            ACTIVE_FUELTOKEN = IERC20(fueltoken_address);
            collectAddress = new_collectAddress;
            GET_ERC721 = IGET_ERC721(address_erc721);
            taxRateGlobal = taxrate_global; 
            isFuelLocked = false;
        }

    // total amount of GET that is held by all NFTs that are still on the balances in the backpacks
    mapping(address => uint256) private balanceAllBackpacks;

    // total amount of GET that has been collected by the depot, by charging the protocol tax for performing a statechange
    mapping(address => uint256) private GETCollectedDepot;
    
    // address that will receive all the sweeped GET, either a contract (like feeCollector) or it could be 
    address private collectAddress;
    
    uint64 public priceGETUSD;

    uint64 public taxRateGlobal;

    // data struct that stores the amount of GET that is in the rucksack of an NFT
    // NFTINDEX 23111 => 33432 wei GET in tank etc
    // NFTINDEX 99122 => 943 wei GET in tank etc
    mapping (address => mapping(uint256 => uint256)) private nftBackpackBalance;
    mapping (uint256 => address) private nftFuelRegistery;    

    // used to store if an NFT exsits
    mapping (uint256 => bool) private NFTIndexBool;

    event depotSwiped(
        uint256 totalAmountSwiped,
        address fuelAddress
    );

    event NewFeeCollecterAddressSet(
        address newCollectorAddress
    );

    event statechangeTaxed(
        uint256 nftIndex,
        uint64 GETTaxedAmount,
        address fuelAddress
    );

    event fuelAddressChanged(
        address newFuelAddress
    );

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack,
        address fuelAddress
    );

    event nftTankWiped(
        uint256 nftIndex,
        uint256 amountDeducted
    );

    event fuelLocked(
        address lockedFuelTokenAddress
    );

    event priceUpdated(
        uint64 getPrice
    );

    // MODIFIERS 
    
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
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY DP");
        _;
    }

    // CONTRACT CONFIGURATION

    /**
    @notice can only be called by goverance
    @param new_collectAddress EOA or contract address that is the only possibile recipient of the collected fees
    
     */
    function setCollectAddress(
        address new_collectAddress
    ) public onlyAdmin {

        collectAddress = new_collectAddress;

        emit NewFeeCollecterAddressSet(new_collectAddress);

    }

    function syncGETPrice() public {

        priceGETUSD = ECONOMICS.getGETPrice();

        emit priceUpdated(
            priceGETUSD
        );

    }

    /**
    @param newFuelTokenAddress ERC20 token address that should be used as the new type of fuel
    */
    function editDefaultFuelAddress(
        address newFuelTokenAddress
    ) external onlyAdmin {

        require(isFuelLocked == false, "FUEL_LOCKED");

        ACTIVE_FUELTOKEN = IERC20(newFuelTokenAddress);

        emit fuelAddressChanged(
            newFuelTokenAddress
        );
    }

    /**
    @notice this function can only be called once, there is no way to undo this!
    */
    function lockFuelAddress() public onlyGovernance {

        isFuelLocked = true;

        emit fuelLocked(
            address(ACTIVE_FUELTOKEN)
        );
    }

    // GET PROTOCOL OPERATIONAL FUNCTIONS

    /** moves all the collected tokens to the collectAddress
    @param fuelAddress address of the ERC20 token you want to swipe the balances of to the collector address
    @notice anybody can call this function
     */
    function swipeCollected(
        address fuelAddress
        ) public returns(uint256) {

        IERC20 FUEL = IERC20(fuelAddress);

        // if (swipeBalance) {
        //     uint256 _preswipebal = GETCollectedDepot;
        // } else {
        //     uint256 _preswipebal = ACTIVEFUEL.balanceOf(address(this));
        // }

        uint256 _preswipebal = GETCollectedDepot[fuelAddress];

        require(_preswipebal > 0, "NOTHING_TO_SWIPE");

        require(
            FUEL.transfer(
                collectAddress,
                _preswipebal),
            "SWIPE_FAILED"
        );

        // set balance to zero TODO FIX
        GETCollectedDepot[fuelAddress] = 0;  

        emit depotSwiped(
            _preswipebal,
            fuelAddress
            );

        return _preswipebal;

    }

    /** each getNFT requires a certain amount of GET 
    @notice this function is called exclusively from the economics contract
    @param nftIndex index of the NFT that is being fueled up 
    @param amountBackpack amount of GET that needs to be charged onto the nftIndex in the depot
     */
    function fuelBackpack(
        uint256 nftIndex,
        uint256 amountBackpack
    ) external onlyFactory returns (bool) {

        require(amountBackpack > 0, "FUEL_AMOUNT_INVALID");

        require(nftBackpackBalance[address(ACTIVE_FUELTOKEN)][nftIndex] == 0, "NFT_ALREADY_FUELED");

        require( // requires token approval
            ACTIVE_FUELTOKEN.transferFrom(
                msg.sender, 
                address(this),
                amountBackpack),
            "FUELBACKPACK_FAILED"
        );

        // add amount transferred to NFT backpac balance
        nftBackpackBalance[address(ACTIVE_FUELTOKEN)][nftIndex] = amountBackpack;

        // register that the NFT exists
        NFTIndexBool[nftIndex] = true;

        // add amount transferred to total collected by depot contract
        balanceAllBackpacks[address(ACTIVE_FUELTOKEN)] += amountBackpack;

        nftFuelRegistery[nftIndex] = address(ACTIVE_FUELTOKEN);

        // emit BackPackFueled(
        //     nftIndex,
        //     amountBackpack,
        //     address(ACTIVE_FUELTOKEN)
        // );

        return true;

    }


    /**
    @dev this function charges the baseRateGlobal rate as set in the contract
    @param nftIndex uniqe id of NFT that needs to be taxed
    @notice no tokens will move due to a taxation event. A taxation is handled with internal bookkeeping, the swipe/wipe function resets the internal bookkeeping and settles on-chain the collected GET to the burn address or treasurya
     */
    function chargeProtocolTax(
        uint256 nftIndex
    ) external onlyFactory returns(uint256) {

        IERC20 FUEL = IERC20(nftFuelRegistery[nftIndex]);

        // fetch backpack balance of NFT by nftIndex
        uint256 _current = nftBackpackBalance[address(FUEL)][nftIndex];

        // backpack has no balance, needs to be fueled, fail tx!
        require(_current > 0, "NO_BALANCE_NO_INDEX");

        // multiply tax rate by GET in backpack
        uint256 _deduct = _current.mul(taxRateGlobal).div(10000);

        // deduct the tax from the internal backpack balance of the nft
        nftBackpackBalance[address(FUEL)][nftIndex] -= _deduct;
        
        // internal bookkeeping, add the deducted amount to the total collected balance
        GETCollectedDepot[address(FUEL)] += _deduct;
        
        // internal bookkeeping deduct from the total balance left in all backpacks 
        balanceAllBackpacks[address(FUEL)] -= _deduct;

        // emit statechangeTaxed(
        //     nftIndex,
        //     uint64(_deduct),
        //     address(FUEL)
        // );

        return _deduct;

    }

    function withdrawFuel(
        address _token, 
        address _toAddress, 
        uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(_toAddress, _amount);
    }

    // VIEW FUNCTIONS

    function backpackBalanceOf(
        uint256 nftIndex
    ) public view returns(uint256) {
        return nftBackpackBalance[nftFuelRegistery[nftIndex]][nftIndex];
    }

    function getActiveFuel() public view returns(address) {
        return address(ACTIVE_FUELTOKEN);
    }

}