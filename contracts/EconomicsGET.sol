// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoundationContract.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/ReentrancyGuardUpgradeable.sol";

contract EconomicsGET is FoundationContract, ReentrancyGuardUpgradeable {

    function __EconomicsGET_init_unchained() internal initializer { }

    function __EconomicsGET_init(
        address _configurationAddress
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
            _configurationAddress);
        __EconomicsGET_init_unchained();
    }


    // data structure containing all the different rates for a particular relayer
    // 100% (1) 10000, 10% (0.1) = 1000, 1% (0.01) = 100, 0.1% (0.001) = 10, 0.01% (0.0001) ---> scaled by 10 000
    // USD values (min, max) are scaled by 1000
    struct DynamicRateStruct {
        bool configured;
        uint32 mintRate; // 1
        uint32 resellRate; // 2
        uint32 claimRate; // 3
        uint32 crowdRate; // 4
        uint32 scalperFee; // 5
        uint32 extraFee; // 6
        uint32 shareRate; // 7
        uint32 editRate; // 8
        uint32 maxBasePrice; // 9
        uint32 minBasePrice; // 10
        uint32 reserveSlot_1; // 11
        uint32 reserveSlot_2; // 12
    }

    // data structure containing all data of a topUp (receipt)
    struct TopUpReceipt {
        uint256 amountToppedUp;  // in wei 1GET = 1e18
        uint256 priceGETUSDTopUp; // in usd $1 = 1e3
        uint256 newDCAPrice;  // in usd $1 = 1e3
    }

    // struct storing the accumulated DCA stats of a relayer
    struct RelayerDCAStruct {
        uint256 totalPaidUSD; // in usd $1 = 1e3
        uint256 totalTokens; // in wei 1GET = 1e18
    }

    // ticketeer identity(relayer) to their fee configuration struct
    mapping(address => DynamicRateStruct) private relayerRates;

    // tracking of the amount of top ups done by this realyer
    mapping(address => uint256) private topUpsRelayerCount;

    // cached mintrate x relayerGETPrice x 100000000
    mapping(address => uint256) private cachedMintFactor;

    // nested mapping containing the indexed receipts of a relayer
    mapping(address => mapping(uint => TopUpReceipt)) private receiptDrawer;

    // mapping with relayer silo balance, in GET, in wei 1e18
    mapping(address => uint256) private relayerSiloBalance;

    // mapping storing the average price per GET topped up (used to value GET in silo)
    mapping(address => RelayerDCAStruct) private relayerDCAs;

    // the relayerGETPrice of a relayer (the USD/GET price the silo balance is valued at)
    mapping(address => uint256) private relayerGETPrice;

    // mapping of basic_balance of NFT by nftIndex
    mapping(uint256 => uint256) private backpackBasicBalance;

    // mapping of upsell_balance of NFT by nftIndex
    // mapping(uint256 => uint256) private backpackUpsellBalance;

    // count of total amount of collected GET
    uint256 private collectedDepot;

    // average NFT basePrice of a relayer (x1000)
    mapping(address => uint256) private averageBasePrice;

    // mapping used to track what relayers are configured properly
    mapping(address => bool) private isRelayerConfigured;

    // mapping between buffer and relayer
    mapping(address => address) private relayerBufferAddress;


    // EVENTS ECONOMICS GET

    event AveragePriceUpdated(
        address indexed relayerUpdated,
        uint256 indexed oldRelayerPrice,
        uint256 indexed newRelayerPrice
    );

    event RelayerToppedUp(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    ); 

    event RelayerToppedUpBuffer(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    );

    event AverageSiloPriceUpdated(
        address relayerAddress,
        uint256 oldPrice,
        uint256 newPrice
    );

    event SiloBalanceCorrected(
        address relayerAddress,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 difference
    );

    event DepotSwiped(
        address feeCollectorAddress,
        uint256 balance
    );

    event RelayerConfiguration(
        address relayerAddress,
        uint32[12] dynamicRates
    );

    event BackPackDrainedBasic(
        uint256 nftIndex,
        uint256 amountCollected
    );

    event BackPackDrainedUpsell(
        uint256 nftIndex,
        uint256 amountCollected
    );

    event ReceiptInDrawer(
        address relayerAddress,
        uint256 amountToppedUp
    );

    event FeeCollectorSet(
        address newFeeCollector
    );

    event FactorUpdated(
        address relayerAddress,
        uint256 mintFactor
    );

    event RelayerConfigurationCleared(
        address relayerAddress
    );

    event CollectedDepotNullified(
        uint256 newDepotBalance
    );

    event RelayerBufferMapped(
        address relayerAddress,
        address bufferAddressRelayer
    );

    // MODIFIERS ECONOMICSGET //

    modifier onlyConfigured(address _relayerAddress) {
        require(
            isRelayerConfigured[_relayerAddress], "RELAYER_NOT_CONFIGURED");
        _;
    }

    /// OPERATIONAL FUNCTIONS

    /**
    @param _relayerAddress the relayer address the new relayerRateStruct belongs to
    @param  dynamicRates array containing all the dyanmic rates x10 000
     */
    function setDynamicRateStruct(
        address _relayerAddress,
        uint32[12] calldata dynamicRates
    ) external onlyAdmin {

        require(_relayerAddress != address(0), "ADDRESS_ZERO");

        for (uint i = 0; i < 10; i++) { // check if rates and prices are positive
            require(dynamicRates[i] >= 0, "RATE_BELOW_ZERO");
        }

        // storing the new configuration in gas effiicent manner
        DynamicRateStruct storage _rates = relayerRates[_relayerAddress];
        _rates.configured = true;
        _rates.mintRate = dynamicRates[0]; // 1
        _rates.resellRate = dynamicRates[1]; // 2
        _rates.claimRate = dynamicRates[2]; // 3
        _rates.crowdRate = dynamicRates[3]; // 4
        _rates.scalperFee = dynamicRates[4]; // 5
        _rates.extraFee = dynamicRates[5]; // 6
        _rates.shareRate = dynamicRates[6]; // 7
        _rates.editRate = dynamicRates[7]; // 8
        _rates.maxBasePrice = dynamicRates[8]; // 9
        _rates.minBasePrice = dynamicRates[9]; // 10
        _rates.reserveSlot_1 = dynamicRates[10]; // 11
        _rates.reserveSlot_2 = dynamicRates[11]; // 12

        if (relayerBufferAddress[_relayerAddress] != address(0x0)) {
            isRelayerConfigured[_relayerAddress] = true;
        }
        
        _updateMintFactor(_relayerAddress, dynamicRates[0]);

        emit RelayerConfiguration(
            _relayerAddress,
            dynamicRates
        );

    }

    function setRelayerBuffer(
        address _relayerAddress,
        address _bufferAddressRelayer
    ) external onlyAdmin {

        relayerBufferAddress[_relayerAddress] = _bufferAddressRelayer;

        if (relayerRates[_relayerAddress].configured == true) {
            isRelayerConfigured[_relayerAddress] = true;
        }

        emit RelayerBufferMapped(
            _relayerAddress,
            _bufferAddressRelayer
        );
    }

    /** clears out the configured dynamic rates of a relayer
    @param _relayerAddress address of the relayer
     */
    function clearDynamicRateStruct(
        address _relayerAddress
    ) external onlyAdmin {

        delete relayerRates[_relayerAddress];

        isRelayerConfigured[_relayerAddress] = false;
        cachedMintFactor[_relayerAddress] = 0;

        emit RelayerConfigurationCleared(_relayerAddress);

    }

    /**  calculates average GET price for relayer after an topup (DCA price of GET top ups)
    @param _topUpAmount amount of GET that has been topped up x10^18
    @param _priceGETTopUp USD price per GET that is being topped in the silo
    @param _relayerAddress relayeraddress that has topped up their silo
    */
    function _calculateNewAveragePrice(
        uint256 _topUpAmount, 
        uint256 _priceGETTopUp, 
        address _relayerAddress
    ) internal returns(uint256) {

        // fetch the old silo value of the relayer
        uint256 _siloprice = relayerGETPrice[_relayerAddress];
        
        if(_siloprice == 0) { // this is the first topUp of this relayer

            // first top up, so all GET is valued at the same price regardless of amount topped up
            relayerGETPrice[_relayerAddress] = _priceGETTopUp;

            // store total voluem USD
            relayerDCAs[_relayerAddress].totalPaidUSD = (_topUpAmount * _priceGETTopUp);

            // store total amount of GET topped up
            relayerDCAs[_relayerAddress].totalTokens = _topUpAmount;

            emit AveragePriceUpdated(
                _relayerAddress, 
                0, 
                _priceGETTopUp
            );

            return _priceGETTopUp;

        } 
        
        // there have been topUps before by this relayer, we need to average the price
        // _newAveragePrice = ((total revenue pas top ups) + (revenue current topUp)) / ((amount GET topped up in the pas) + (amount topped up now))
        uint256 _newPrice =  (relayerDCAs[_relayerAddress].totalPaidUSD + (_topUpAmount * _priceGETTopUp)) / (relayerDCAs[_relayerAddress].totalTokens + _topUpAmount);

        // update the total revenue USD topped up
        relayerDCAs[_relayerAddress].totalPaidUSD += _topUpAmount * _priceGETTopUp;

        // update the total amount of GET historically topped up
        relayerDCAs[_relayerAddress].totalTokens += _topUpAmount;

        // update silo price
        relayerGETPrice[_relayerAddress] = _newPrice;

        emit AverageSiloPriceUpdated(
            _relayerAddress, 
            _siloprice, 
            _newPrice
        );

        return _newPrice;
        
    }

    // /** @notice tops up the silo balance of a relayer, relayer itself pays the fuel tokens 
    // @param _topUpAmount amount of fuel tokens that will be topped up
    // @param _priceGETTopUp USD price per GET that is paid and will be locked
    // @param _relayerAddress address of relayer
    // */
    // function topUpRelayer(
    //         uint256 _topUpAmount,
    //         uint256 _priceGETTopUp,
    //         address _relayerAddress
    //     ) external onlyAdmin nonReentrant onlyConfigured(_relayerAddress) returns(uint256) {

    //         require(_topUpAmount > 0, "ZERO_TOPPED_UP");
    //         require(_priceGETTopUp > 0 || _priceGETTopUp != 0, "INVALID_GET_PRICE");

    //         // check if the relayer has enough fuel tokens on their address to topUp
    //         require(
    //             FUELTOKEN.balanceOf(
    //                 _relayerAddress) >= _topUpAmount,
    //             "BALANCE_TOO_LOW"
    //         );           

    //         // check if relayer has allowed the economicsGET contract to move tokens on their behalf
    //         require(
    //             FUELTOKEN.allowance(
    //                 _relayerAddress, 
    //                 address(this)) >= _topUpAmount,
    //             "ALLOWANCE_FAILED_TOPUPGET"
    //         );

    //         // transfer fuel tokens from relayer address to economicsGET
    //         (bool topUpFuel) = FUELTOKEN.transferFrom(
    //             _relayerAddress,
    //             address(this),
    //             _topUpAmount
    //         );
    //         require(topUpFuel, "TRANSFER_FAILED_TOPUPGET");
        
    //         // update silo balance of the relayer
    //         relayerSiloBalance[_relayerAddress] += _topUpAmount;

    //         // update the average silo price, as the topUp might have effected the average DCA topup
    //         uint256 _newSiloPrice = _calculateNewAveragePrice(_topUpAmount, _priceGETTopUp, _relayerAddress);

    //         topUpsRelayerCount[_relayerAddress] += 1;

    //         _storeTopUpReceipt(_relayerAddress, _priceGETTopUp, _topUpAmount, _newSiloPrice);

    //         // as the silo price is updated, the mintFactor needs to be recalculated
    //         _updateMintFactor(_relayerAddress, relayerRates[_relayerAddress].mintRate);

    //         emit RelayerToppedUp(
    //             _relayerAddress,
    //             _topUpAmount,
    //             _priceGETTopUp,
    //             _newSiloPrice
    //         );

    //         // return the new silo balance
    //         return relayerSiloBalance[_relayerAddress];
        
    // }


    /** @notice tops up the silo balance of a relayer, buffer pays the fuel tokens 
    @param _topUpAmount amount of fuel tokens that will be topped up
    @param _priceGETTopUp USD price per GET that is paid and will be locked
    @param _relayerAddress address of relayer
    */
    function topUpRelayerFromBuffer(
            uint256 _topUpAmount,
            uint256 _priceGETTopUp,
            address _relayerAddress
        ) external onlyAdmin nonReentrant onlyConfigured(_relayerAddress) returns(uint256) {

            require(_topUpAmount > 0, "ZERO_TOPPED_UP");
            
            require(_priceGETTopUp > 0 || _priceGETTopUp != 0, "INVALID_GET_PRICE");

            // check if the relayer has enough fuel tokens on their address to topUp
            require(
                FUELTOKEN.balanceOf(
                   relayerBufferAddress[_relayerAddress]) >= _topUpAmount,
                "BALANCE_BUFFER_TOO_LOW"
            );           

            // check if relayer has allowed the economicsGET contract to move tokens on their behalf
            require(
                FUELTOKEN.allowance(
                    relayerBufferAddress[_relayerAddress], 
                    address(this)) >= _topUpAmount,
                "ALLOWANCE_BUFFER_ERROR"
            );

            // transfer fuel tokens from buffer address to economicsGET
            (bool topUpFuel) = FUELTOKEN.transferFrom(
                relayerBufferAddress[_relayerAddress],
                address(this),
                _topUpAmount
            );
            require(topUpFuel, "TRANSFER_FAILED_TOPUPGET");
        
            // update silo balance of the relayer
            relayerSiloBalance[_relayerAddress] += _topUpAmount;

            // update the average silo price, as the topUp might have effected the average DCA topup
            uint256 _newSiloPrice = _calculateNewAveragePrice(_topUpAmount, _priceGETTopUp, _relayerAddress);

            topUpsRelayerCount[_relayerAddress] += 1;

            _storeTopUpReceipt(_relayerAddress, _priceGETTopUp, _topUpAmount, _newSiloPrice);

            // as the silo price is updated, the mintFactor needs to be recalculated
            _updateMintFactor(_relayerAddress, relayerRates[_relayerAddress].mintRate);

            emit RelayerToppedUpBuffer(
                _relayerAddress,
                _topUpAmount,
                _priceGETTopUp,
                _newSiloPrice
            );

            // return the new silo balance
            return relayerSiloBalance[_relayerAddress];
        
    }


    /** stores topUp receipt in the contract
    @param _relayerAddress address of relayer that is topped up
    @param _amountToppedUp amount of GET in wei being topped up
    @param _newAverageSiloPrice the USD value per GET x1000 of the 
     */
    function _storeTopUpReceipt(
        address _relayerAddress,
        uint256 _priceGETUSDOrder,
        uint256 _amountToppedUp,
        uint256 _newAverageSiloPrice
    ) internal {

        TopUpReceipt storage receipts =  receiptDrawer[_relayerAddress][topUpsRelayerCount[_relayerAddress]];
        
        receipts.amountToppedUp = _amountToppedUp;
        receipts.priceGETUSDTopUp = _priceGETUSDOrder;
        receipts.newDCAPrice = _newAverageSiloPrice;

        emit ReceiptInDrawer(
            _relayerAddress,
            _amountToppedUp
        );
    }
    
    /**
    @param _nftIndex index of the nft that is being fueled
    @param _relayerAddress address of the relayer requesting and paying for the mint
    @param _basePrice usd price multiplied by 1e3 of the nft
    @return uint256 the amount of GET in wei 1e18 that is fueled into the backpack
     */
    function _refineFuel(
        uint256 _nftIndex,
        address _relayerAddress,
        uint256 _basePrice
    ) internal returns(uint256) {

        // calculate how much GET equates to the FIAT value needed in the backpack
        uint256 _amountget = _basePrice * cachedMintFactor[_relayerAddress];

        // check if silo balance is sufficient to fuel the backpack
        require( 
            _amountget < relayerSiloBalance[_relayerAddress],
        "SILO_BALANCE_INSUFFICIENT"
        );

        // update silo balance
        relayerSiloBalance[_relayerAddress] -= _amountget;

        // add balance to backpack balance
        backpackBasicBalance[_nftIndex] = _amountget;

        return _amountget;
    }

    /**  fuels NFT backpack, called from primarySale()
    @param _nftIndex index of NFT that is minted
    @param _relayerAddress address of relayer that will be billed
    @param _basePrice USD price of ticket order (mulitplied by 1000)
    @notice if min_base_price is 0, free tickets cost no GET fuel
    */
    function fuelBackpackTicket(
        uint256 _nftIndex,
        address _relayerAddress,
        uint256 _basePrice
        ) external onlyFactory onlyConfigured(_relayerAddress) returns (uint256) 
        {   
            uint32 _min = relayerRates[_relayerAddress].minBasePrice;
            // baseprice is below minimum, minimum price is used for fuel calculation
            if (_basePrice < _min) {
                return _refineFuel(_nftIndex, _relayerAddress, _min);
            }
            uint32 _max = relayerRates[_relayerAddress].maxBasePrice;
            // baseprice is above minimum, maximim price is used for fuel calculation
            if(_basePrice > _max) {
                return _refineFuel(_nftIndex, _relayerAddress, _max);
            }
            // baseprice is in between min/max, nft value is used for fuel calculation
            return _refineFuel(_nftIndex, _relayerAddress, _basePrice);

    }

   /** @notice tax the basic backpack of a nftIndex
    @param _nftIndex nftIndex being taxed
    returns amount that has been taxed by the DAO 
    */
    function chargeTaxRateBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {

        uint256 _tax = CONFIGURATION.basicTaxRate() * backpackBasicBalance[_nftIndex] / 1_00_00;

        // add _tax to collectedDepot
        collectedDepot += _tax;

        // deduct from backpack balance
        backpackBasicBalance[_nftIndex] -= _tax;

        return _tax;

    }

    /** empties the basic backpack of an nftex 
    @param _nftIndex nftIndex being emptied
    returns amount of GET that was in the backpack
    */
    function emptyBackpackBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {

        // check if nftIndex exists
        require(GET_ERC721.isNftIndex(_nftIndex), "ECONOMICS_INDEX_UNKNOWN");

        // fetch current balance of backpack
        uint256 _bal = backpackBasicBalance[_nftIndex];

        if (_bal == 0) {
            return 0;
        }

        // add _tax to collectedDepot (for the DAO)
        collectedDepot += _bal;

        // set basic backpack balance to 0
        delete backpackBasicBalance[_nftIndex];

        return _bal;

    } 

    /** 
    @param _relayerAddress the relayerAddress of the silo that needs to be corrected
    @param _newBalance the correct/intended balance of the silo in GET 
    @notice the collectedDepot balance will be used as 'counter post' 
     */
    function correctBalanceSilo(
        address _relayerAddress,
        uint256 _newBalance /** in wei */
    ) external onlyAdmin {

        uint256 _oldBalance = relayerSiloBalance[_relayerAddress];
        uint256 _difference;

        // calculate the difference between new and old, to correct the Depot balnce. Could be positive and negative
        if (_newBalance > _oldBalance) {
            // Process refund to relayer
            // _difference is negative so remove from the collectedDepot by getting the positive difference.
            _difference = (_newBalance - _oldBalance);
            require(_difference < collectedDepot, "NOT_ENOUGH_IN_DEPOT");
            collectedDepot = collectedDepot - _difference;
        } else {
            // Process balance correction to depot
            // _difference is positive, reverse _old + _new to get positive difference and add.
            collectedDepot = collectedDepot + (_oldBalance - _newBalance);
         }


        emit SiloBalanceCorrected(
            _relayerAddress,
            _oldBalance,
            _newBalance,
            _difference
        );
    
    }

    /** resets the collectedDepot balance.
    @notice function is useful for if for whatever reason the balance doesn't reflecft what has been truely collected
     */
    function correctedDepotCorrection(
        uint256 _newDepotBalance
    ) external onlyAdmin {
        require(_newDepotBalance > 0, "NEW_BALANCE_NEGATIVE");

        collectedDepot = _newDepotBalance;

        emit CollectedDepotNullified(
            _newDepotBalance
        );

    }

    /**
    @notice moves GET from the depot to the feeCollectorAddress
    @dev this function can be called by anyone
     */
    function swipeDepotBalance() external nonReentrant returns(uint256) {
        require(collectedDepot > 0, "NOTHING_TO_SWIPE");

        uint256 _balanceContract = FUELTOKEN.balanceOf(address(this));
        uint256 _balanceDepot = collectedDepot;

        // it is possible that people send GET 'for fun' to the depot contract, due to this we cannot rely on the fuel balance to exactly match the collectedDepot balance (even though it technicall needs to match)
        require(_balanceContract >= collectedDepot, "COLLECTED_BALANCE_INVALID");
        
        // if stable transfer was successful, transferring the fractions to the buyer 
        (bool swipeFuel) = FUELTOKEN.transfer(CONFIGURATION.feeCollectorAddress(), _balanceDepot);
        require(swipeFuel, "SWIPEDEPOT_FAILED");

        emit DepotSwiped(
            CONFIGURATION.feeCollectorAddress(),
            _balanceDepot
        );

        collectedDepot = 0;

        return _balanceDepot;

    }

    function _updateMintFactor(
        address _relayerAddress,
        uint32 _mintRate
    ) internal {

        uint256 _getprice = relayerGETPrice[_relayerAddress];

        if (_getprice == 0) { // silo has no price yet
            _getprice = CONFIGURATION.priceGETUSD();  // fallback to global GET price
        }

        if (_mintRate == 0) { // relayer not yet configured
            _mintRate = 300; // this is a meaningless default figure as it will always be overwritten after a configuration of the relayerRates
        }

        uint256 _mintFactor = ((_mintRate * 1000) / _getprice) * 1_00000_00000_0;

        cachedMintFactor[_relayerAddress] = _mintFactor;

        emit FactorUpdated(
            _relayerAddress,
            _mintFactor
        );

    }

    //// VIEW FUNCTIONS ////

    function checkRelayerConfiguration(
        address _relayerAddress
    ) external view returns (bool) {
        return isRelayerConfigured[_relayerAddress];
    }

    /** the GET balance in wei of relayer
    @param _relayerAddress address of integrator/ticketeer
     */
    function balanceRelayerSilo(
        address _relayerAddress
    ) external view returns (uint256) 
    {   
        return relayerSiloBalance[_relayerAddress];
    }

    /**  returns USD value of the GET in the relayers silo
    @param _relayerAddress address of relayer
    @notice the output will be 1e3 higher as it an USD value
    */
    function valueRelayerSilo(
        address _relayerAddress
    ) public view returns(uint256) {
        //
        return (relayerGETPrice[_relayerAddress] * relayerSiloBalance[_relayerAddress]) / 1_00000_00000_00000_000 /** correct for wei denomination dividing by 1e18 */;
    }

    /** estimates the amount of mints a relayer can do based on averageBasePrice and configured mintRate, using the silo value
    @param _relayerAddress address of relayer
    TODO check if this is correct
    */
    function estimateNFTMints(
        address _relayerAddress
    ) external view returns(uint256) {
        // 1000 / 1000 * 10 000
        return valueRelayerSilo(_relayerAddress) / (averageBasePrice[_relayerAddress] * relayerRates[_relayerAddress].mintRate / 1_00_00 /** correct for rate 1e4 */);
    }
    
    function viewRelayerRates(
        address _relayerAddress
    ) external view returns (DynamicRateStruct memory) 
    {
        return relayerRates[_relayerAddress];
    }

    // returns the baseMint factor (catched for reduced gas costs)
    function viewRelayerFactor(
        address _relayerAddress
    ) external view returns (uint256) {
        return cachedMintFactor[_relayerAddress];
    }

    // returns the GET silo rate of a relayer 
    function viewRelayerGETPrice(
        address _relayerAddress 
    ) external view returns (uint256) {
        return relayerGETPrice[_relayerAddress];
    }

    // returns GET balance in WEI of a relayer silo
    function viewBackPackBalance(
        uint256 _nftIndex
    ) external view returns (uint256) {
        return backpackBasicBalance[_nftIndex];
    }

    // returns the value of the GET in the backpack using the silo rate of the relayer that minted the NF 
    function viewBackPackValue(
        uint256 _nftIndex,
        address _relayerAddress
    ) external view returns (uint256) {
        return (backpackBasicBalance[_nftIndex] * relayerGETPrice[_relayerAddress]) / 1_00000_00000_00000_000;
    }

    function viewDepotBalance() external view returns(uint256) {
        return collectedDepot;
    }

    function viewDepotValue() external view returns(uint256) {
        return (collectedDepot * CONFIGURATION.priceGETUSD()) / 1_00000_00000_00000_000;
    }
}