//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./utils/OwnableUpgradeable.sol";

import "./interfaces/IsyncConfiguration.sol";
import "./interfaces/IGETProtocolConfiguration.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract GETProtocolConfiguration is Initializable, ContextUpgradeable, OwnableUpgradeable {

    address public GETgovernanceAddress;
    address payable public feeCollectorAddress; 
    address payable public treasuryDAOAddress;
    address payable public stakingContractAddress;
    address payable public emergencyAddress; 
    address payable public bufferAddressGlobal;

    address private proxyAdminAddress;
    address public AccessControlGET_proxy_address;
    address public baseGETNFT_proxy_address;
    address public getNFT_ERC721_proxy_address;
    address public eventMetadataStorage_proxy_address;
    address public getEventFinancing_proxy_address;
    address public economicsGET_proxy_address;
    address public fueltoken_get_address;

    /// global economics configurations (Work in progress)
    uint256 public basicTaxRate;

    /// GET and USD price oracle/price feed configurations (work in progress)
    uint256 public priceGETUSD; // x1000
    IUniswapV2Pair public liquidityPoolGETETH;
    IUniswapV2Pair public liquidityPoolETHUSDC;

    function __GETProtocolConfiguration_init_unchained() public initializer {}

    function __GETProtocolConfiguration_init() public initializer {
        __Context_init();
        __Ownable_init();
        __GETProtocolConfiguration_init_unchained();
    }

    /// EVENTS

    event UpdateAccessControl(address _old, address _new);
    event UpdatebaseGETNFT(address _old, address _new);
    event UpdateERC721(address _old, address _new);
    event UpdateMetdata(address _old, address _new);
    event UpdateFinancing(address _old, address _new);
    event UpdateEconomics(address _old, address _new);
    event UpdateFueltoken(address _old, address _new);

    event UpdateGoverance(address _old, address _new);
    event UpdateFeeCollector(address _old, address _new);
    event UpdateTreasuryDAO(address _old, address _new);
    event UpdateStakingContract(address _old, address _new);
    event UpdateBasicTaxRate(uint256 _old, uint256 _new);
    event UpdateGETUSD(uint256 _old, uint256 _new);
    event UpdateBufferGlobal(address _old, address _new);

    event UpdateLiquidityPoolAddress(
        address _oldPoolGETETH, 
        address _oldPoolUSDCETH, 
        address _newPoolGETETH, 
        address _newPoolUSDCETH
    );

    /// INITIALIZATION

    // this function only needs to be used once, after the initial deploy
    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external onlyOwner {
        // require(isContract(_access_control_proxy), "_access_control_proxy not a contract");
        AccessControlGET_proxy_address = _access_control_proxy;

        // require(isContract(_base_proxy), "_base_proxy not a contract");
        baseGETNFT_proxy_address = _base_proxy;

        // require(isContract(_erc721_proxy), "_erc721_proxy not a contract");
        getNFT_ERC721_proxy_address = _erc721_proxy;

        // require(isContract(_metadata_proxy), "_metadata_proxy not a contract");
        eventMetadataStorage_proxy_address = _metadata_proxy;

        // require(isContract(_financing_proxy), "_financing_proxy not a contract");
        getEventFinancing_proxy_address = _financing_proxy;

        // require(isContract(_economics_proxy), "_economics_proxy not a contract");
        economicsGET_proxy_address = _economics_proxy;
    
        // sync the change across all proxies
        _callSync();

    }

    // setting a new AccessControlGET_proxy_address Proxy address
    function setAccessControlGETProxy(
        address _access_control_proxy
        ) external onlyOwner {
        
        require(isContract(_access_control_proxy), "_access_control_proxy not a contract");

        emit UpdateAccessControl(
            AccessControlGET_proxy_address, 
            _access_control_proxy
        );

        AccessControlGET_proxy_address = _access_control_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setBASEProxy(
        address _base_proxy) external onlyOwner {
        
        require(isContract(_base_proxy), "_base_proxy not a contract");

        emit UpdatebaseGETNFT(
            baseGETNFT_proxy_address, 
            _base_proxy
        );

         baseGETNFT_proxy_address = _base_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setERC721Proxy(
        address _erc721_proxy) external onlyOwner {
        
        require(isContract(_erc721_proxy), "_erc721_proxy not a contract");

        emit UpdateERC721(
            getNFT_ERC721_proxy_address, 
            _erc721_proxy
        );

        getNFT_ERC721_proxy_address = _erc721_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setMetaProxy(
        address _metadata_proxy) external onlyOwner {
        
        require(isContract(_metadata_proxy), "_metadata_proxy not a contract");

        emit UpdateMetdata(
            eventMetadataStorage_proxy_address, 
            _metadata_proxy
        );

        eventMetadataStorage_proxy_address = _metadata_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setFinancingProxy(
        address _financing_proxy) external onlyOwner {
        
        require(isContract(_financing_proxy), "_financing_proxy not a contract");

        emit UpdateFinancing(
            getEventFinancing_proxy_address, 
            _financing_proxy
        );

        getEventFinancing_proxy_address = _financing_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setEconomicsProxy(
        address _economics_proxy) external onlyOwner {
        
        require(isContract(_economics_proxy), "_economics_proxy not a contract");

        emit UpdateEconomics(
            economicsGET_proxy_address, 
            _economics_proxy
        );

        economicsGET_proxy_address = _economics_proxy;

        // sync the change across all proxies
        _callSync();

    }

    function setgetNFT_ERC721(address _getNFT_ERC721) external onlyOwner {

        require(isContract(_getNFT_ERC721), "_getNFT_ERC721 not a contract");

        emit UpdateERC721(getNFT_ERC721_proxy_address, _getNFT_ERC721);

        getNFT_ERC721_proxy_address = _getNFT_ERC721;

        // sync the change across all proxies
        _callSync();

    }    

    function setFueltoken(address _fueltoken_get_address) external onlyOwner {

        require(isContract(_fueltoken_get_address), "_fueltoken_get_address not a contract");

        emit UpdateFueltoken(fueltoken_get_address, _fueltoken_get_address);

        fueltoken_get_address = _fueltoken_get_address;

        // sync the change across all proxies
        _callSync();
        
    }  

    /**
    @notice internal function calling all proxy contracts of the protocol and updating all the global values
     */
    function _callSync() internal {

        // UPDATE BASE
        require(IsyncConfiguration(baseGETNFT_proxy_address).syncConfiguration(), "FAILED_UPDATE_BASE");

        // UPDATE ECONOMICS
        require(IsyncConfiguration(economicsGET_proxy_address).syncConfiguration(), "FAILED_UPDATE_ECONOMICS");

        // UPDATE METADATA
        require(IsyncConfiguration(eventMetadataStorage_proxy_address).syncConfiguration(), "FAILED_UPDATE_METADATA");

        // UPDATE FINANCING 
        require(IsyncConfiguration(getEventFinancing_proxy_address).syncConfiguration(), "FAILED_UPDATE_FINANCE");

    }

    // MANAGING GLOBAL VALUES


    function setGovernance(
        address _newGovernance
    ) external onlyOwner {

        // require(isContract(_newGovernance), "_newGovernance not a contract");

        emit UpdateGoverance(GETgovernanceAddress, _newGovernance);
        
        GETgovernanceAddress = _newGovernance;
        
    }

    function setFeeCollector(
        address payable _newFeeCollector
    ) external onlyOwner {

        require(_newFeeCollector != address(0), "_newFeeCollector cannot be burn address");
        
        emit UpdateFeeCollector(feeCollectorAddress, _newFeeCollector);

        feeCollectorAddress = _newFeeCollector;
        
    }    

    function setBufferAddressGlobal(
        address payable _newBufferGlobal
    ) external onlyOwner {

        require(_newBufferGlobal != address(0), "_newBuffer cannot be burn address");
        
        emit UpdateBufferGlobal(bufferAddressGlobal, _newBufferGlobal);

        bufferAddressGlobal = _newBufferGlobal;
        
    }    

    function setTreasuryDAO(
        address payable _newTreasury
    ) external onlyOwner {

        require(_newTreasury != address(0), "_newTreasury cannot be 0x0");

        emit UpdateTreasuryDAO(treasuryDAOAddress, _newTreasury);

        treasuryDAOAddress = _newTreasury;

    }

    function setStakingContract(
        address payable _newStaking
    ) external onlyOwner {

        // require(isContract(_newStaking), "_newStaking not a contract");

        emit UpdateStakingContract(stakingContractAddress, _newStaking);

        stakingContractAddress = _newStaking;
        
    }

    function setBasicTaxRate(
        uint256 _basicTaxRate
    ) external onlyOwner {

        require(_basicTaxRate >= 0, "TAXRATE_INVALID");

        emit UpdateBasicTaxRate(basicTaxRate, _basicTaxRate);

        basicTaxRate = _basicTaxRate;
        
    }
    

    /** function that manually sets the price of GET in USD
    @notice this is a temporary approach, in the future it would make most sense to use LP pool TWAP oracles
    @dev as for every other contract the USD value is multiplied by 1000
     */
    function setGETUSD(
        uint256 _newGETUSD
    ) external onlyOwner {
        emit UpdateGETUSD(priceGETUSD, _newGETUSD);
        priceGETUSD = _newGETUSD;
    }

    // function setLiquidityPoolAddresses(
    //     address _poolGETETH,
    //     address _poolUSDCETH
    // ) external onlyOwner {
    //     liquidityPoolGETETH = IUniswapV2Pair(_poolGETETH);
    //     liquidityPoolETHUSDC = IUniswapV2Pair(_poolUSDCETH);
        
    //     emit UpdateLiquidityPoolAddress(
    //         liquidityPoolGETETH,
    //         liquidityPoolETHUSDC,
    //         _poolGETETH,
    //         _poolUSDCETH
    //     );
    // }    

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


}
