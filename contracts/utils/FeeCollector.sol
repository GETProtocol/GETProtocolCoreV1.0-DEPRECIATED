// SPDX-License-Identifier: MIT

pragma solidity = 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import "./interfaces/IFeeCollector.sol";
import "./interfaces/BalancerInterface.sol";

contract FeeCollector is IFeeCollector, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IUniswapV2Router02 private constant uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address private immutable weth;

  // Need to use openzeppelin enumerableset
  EnumerableSet.AddressSet private depositTokens;

  uint256[] private allocations; // 100000 = 100%. allocation sent to beneficiaries
  address[] private beneficiaries; // Who are the beneficiaries of the fees generated from IDLE. The first beneficiary is always going to be the smart treasury

  uint128 public constant MAX_BENEFICIARIES = 5;
  uint128 public constant MIN_BENEFICIARIES = 2;
  uint256 public constant FULL_ALLOC = 100000;

  uint256 public constant MAX_NUM_FEE_TOKENS = 15; // Cap max tokens to 15
  bytes32 public constant WHITELISTED = keccak256("WHITELISTED_ROLE");

  modifier smartTreasurySet {
    require(beneficiaries[0]!=address(0), "Smart Treasury not set");
    _;
  }

  modifier onlyAdmin {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorised");
    _;
  }

  modifier onlyWhitelisted {
    require(hasRole(WHITELISTED, msg.sender), "Unauthorised");
    _;
  }

  constructor (
    address _weth,
    address _feeTreasuryAddress,
    address _idleRebalancer,
    address _multisig,
    address[] memory _initialDepositTokens
  ) public {
    require(_weth != address(0), "WETH cannot be the 0 address");
    require(_feeTreasuryAddress != address(0), "Fee Treasury cannot be 0 address");
    require(_idleRebalancer != address(0), "Rebalancer cannot be 0 address");
    require(_multisig != address(0), "Multisig cannot be 0 address");

    require(_initialDepositTokens.length <= MAX_NUM_FEE_TOKENS);
    
    _setupRole(DEFAULT_ADMIN_ROLE, _multisig); // setup multisig as admin
    _setupRole(WHITELISTED, _multisig); // setup multisig as whitelisted address
    _setupRole(WHITELISTED, _idleRebalancer); // setup multisig as whitelisted address

    // configure weth address and ERC20 interface
    weth = _weth;

    allocations = new uint256[](3); // setup fee split ratio
    allocations[0] = 80000;
    allocations[1] = 15000;
    allocations[2] = 5000;

    beneficiaries = new address[](3); // setup beneficiaries
    beneficiaries[1] = _feeTreasuryAddress; // setup fee treasury address
    beneficiaries[2] = _idleRebalancer; // setup fee treasury address

    address _depositToken;
    for (uint256 index = 0; index < _initialDepositTokens.length; index++) {
      _depositToken = _initialDepositTokens[index];
      require(_depositToken != address(0), "Token cannot be 0 address");
      require(_depositToken != _weth, "WETH not supported"); // There is no WETH -> WETH pool in uniswap
      require(depositTokens.contains(_depositToken) == false, "Already exists");

      IERC20(_depositToken).safeIncreaseAllowance(address(uniswapRouterV2), type(uint256).max); // max approval
      depositTokens.add(_depositToken);
    }
  }

  function deposit(
    bool[] memory _depositTokensEnabled,
    uint256[] memory _minTokenOut,
    uint256 _minPoolAmountOut
  ) public override smartTreasurySet onlyWhitelisted {
    _deposit(_depositTokensEnabled, _minTokenOut, _minPoolAmountOut);
  }

  /**
  @dev implements deposit()
   */
  function _deposit(
    bool[] memory _depositTokensEnabled,
    uint256[] memory _minTokenOut,
    uint256 _minPoolAmountOut
  ) internal {
    uint256 counter = depositTokens.length();
    require(_depositTokensEnabled.length == counter, "Invalid length");
    require(_minTokenOut.length == counter, "Invalid length");

    uint256 _currentBalance;
    IERC20 _tokenInterface;

    uint256 wethBalance;

    address[] memory path = new address[](2);
    path[1] = weth; // output will always be weth
    
    // iterate through all registered deposit tokens
    for (uint256 index = 0; index < counter; index++) {
      if (_depositTokensEnabled[index] == false) {continue;}

      _tokenInterface = IERC20(depositTokens.at(index));

      _currentBalance = _tokenInterface.balanceOf(address(this));
      
      // Only swap if balance > 0
      if (_currentBalance > 0) {
        // create simple route; token->WETH
        
        path[0] = address(_tokenInterface);
        
        // swap token
        uniswapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _currentBalance,
          _minTokenOut[index], 
          path,
          address(this),
          block.timestamp.add(1800)
        );
      }
    }

    // deposit all swapped WETH + the already present weth balance
    // to beneficiaries
    // the beneficiary at index 0 is the smart treasury
    wethBalance = IERC20(weth).balanceOf(address(this));
    if (wethBalance > 0){
      // feeBalances[0] is fee sent to smartTreasury
      uint256[] memory feeBalances = _amountsFromAllocations(allocations, wethBalance);
      uint256 smartTreasuryFee = feeBalances[0];

      if (wethBalance.sub(smartTreasuryFee) > 0){
          // NOTE: allocation starts at 1, NOT 0, since 0 is reserved for smart treasury
          for (uint256 a_index = 1; a_index < allocations.length; a_index++){
            IERC20(weth).safeTransfer(beneficiaries[a_index], feeBalances[a_index]);
          }
        }

      if (smartTreasuryFee > 0) {
        ConfigurableRightsPool crp = ConfigurableRightsPool(beneficiaries[0]); // the smart treasury is at index 0
        crp.joinswapExternAmountIn(weth, smartTreasuryFee, _minPoolAmountOut);
      }
    }
  }

  function setSplitAllocation(uint256[] calldata _allocations) external override smartTreasurySet onlyAdmin {
    _depositAllTokens();

    _setSplitAllocation(_allocations);
  }

  function _setSplitAllocation(uint256[] memory _allocations) internal {
    require(_allocations.length == beneficiaries.length, "Invalid length");
    
    uint256 sum=0;
    for (uint256 i=0; i<_allocations.length; i++) {
      sum = sum.add(_allocations[i]);
    }

    require(sum == FULL_ALLOC, "Ratio does not equal 100000");

    allocations = _allocations;
  }


  function _depositAllTokens() internal {
    uint256 numTokens = depositTokens.length();
    bool[] memory depositTokensEnabled = new bool[](numTokens);
    uint256[] memory minTokenOut = new uint256[](numTokens);

    for (uint256 i = 0; i < numTokens; i++) {
      depositTokensEnabled[i] = true;
      minTokenOut[i] = 1;
    }

    _deposit(depositTokensEnabled, minTokenOut, 1);
  }

  function addBeneficiaryAddress(address _newBeneficiary, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(beneficiaries.length < MAX_BENEFICIARIES, "Max beneficiaries");
    require(_newBeneficiary!=address(0), "beneficiary cannot be 0 address");

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      require(beneficiaries[i] != _newBeneficiary, "Duplicate beneficiary");
    }

    _depositAllTokens();

    beneficiaries.push(_newBeneficiary);

    _setSplitAllocation(_newAllocation);
  }


  function removeBeneficiaryAt(uint256 _index, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(_index >= 1, "Invalid beneficiary to remove");
    require(_index < beneficiaries.length, "Out of range");
    require(beneficiaries.length > MIN_BENEFICIARIES, "Min beneficiaries");
    
    _depositAllTokens();

    // replace beneficiary with index with final beneficiary, and call pop
    beneficiaries[_index] = beneficiaries[beneficiaries.length-1];
    beneficiaries.pop();
    
    // NOTE THE ORDER OF ALLOCATIONS
    _setSplitAllocation(_newAllocation);
  }

  function replaceBeneficiaryAt(uint256 _index, address _newBeneficiary, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(_index >= 1, "Invalid beneficiary to remove");
    require(_newBeneficiary!=address(0), "Beneficiary cannot be 0 address");

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      require(beneficiaries[i] != _newBeneficiary, "Duplicate beneficiary");
    }

    _depositAllTokens();
    
    beneficiaries[_index] = _newBeneficiary;

    _setSplitAllocation(_newAllocation);
  }
  
  function setSmartTreasuryAddress(address _smartTreasuryAddress) external override onlyAdmin {
    require(_smartTreasuryAddress!=address(0), "Smart treasury cannot be 0 address");

    // When contract is initialised, the smart treasury address is not yet set
    // Only call change allowance to 0 if previous smartTreasury was not the 0 address.
    if (beneficiaries[0] != address(0)) {
      IERC20(weth).safeApprove(beneficiaries[0], 0); // set approval for previous fee address to 0
    }
    // max approval for new smartTreasuryAddress
    IERC20(weth).safeIncreaseAllowance(_smartTreasuryAddress, type(uint256).max);
    beneficiaries[0] = _smartTreasuryAddress;
  }


  function addAddressToWhiteList(address _addressToAdd) external override onlyAdmin{
    grantRole(WHITELISTED, _addressToAdd);
  }

  function removeAddressFromWhiteList(address _addressToRemove) external override onlyAdmin {
    revokeRole(WHITELISTED, _addressToRemove);
  }
    
  function registerTokenToDepositList(address _tokenAddress) external override onlyAdmin {
    require(depositTokens.length() < MAX_NUM_FEE_TOKENS, "Too many tokens");
    require(_tokenAddress != address(0), "Token cannot be 0 address");
    require(_tokenAddress != weth, "WETH not supported"); // There is no WETH -> WETH pool in uniswap
    require(depositTokens.contains(_tokenAddress) == false, "Already exists");

    IERC20(_tokenAddress).safeIncreaseAllowance(address(uniswapRouterV2), type(uint256).max); // max approval
    depositTokens.add(_tokenAddress);
  }

  function removeTokenFromDepositList(address _tokenAddress) external override onlyAdmin {
    IERC20(_tokenAddress).safeApprove(address(uniswapRouterV2), 0); // 0 approval for uniswap
    depositTokens.remove(_tokenAddress);
  }

  function withdraw(address _token, address _toAddress, uint256 _amount) external override onlyAdmin {
    IERC20(_token).safeTransfer(_toAddress, _amount);
  }

  function _amountsFromAllocations(uint256[] memory _allocations, uint256 total) internal pure returns (uint256[] memory newAmounts) {
    newAmounts = new uint256[](_allocations.length);
    uint256 currBalance;
    uint256 allocatedBalance;

    for (uint256 i = 0; i < _allocations.length; i++) {
      if (i == _allocations.length - 1) {
        newAmounts[i] = total.sub(allocatedBalance);
      } else {
        currBalance = total.mul(_allocations[i]).div(FULL_ALLOC);
        allocatedBalance = allocatedBalance.add(currBalance);
        newAmounts[i] = currBalance;
      }
    }
    return newAmounts;
  }

  function withdrawUnderlying(address _toAddress, uint256 _amount, uint256[] calldata minTokenOut) external override smartTreasurySet onlyAdmin{
    ConfigurableRightsPool crp = ConfigurableRightsPool(beneficiaries[0]);
    BPool smartTreasuryBPool = crp.bPool();

    uint256 numTokensInPool = smartTreasuryBPool.getNumTokens();
    require(minTokenOut.length == numTokensInPool, "Invalid length");


    address[] memory poolTokens = smartTreasuryBPool.getCurrentTokens();
    uint256[] memory feeCollectorTokenBalances = new uint256[](numTokensInPool);

    for (uint256 i=0; i<poolTokens.length; i++) {
      // get the balance of a poolToken of the fee collector
      feeCollectorTokenBalances[i] = IERC20(poolTokens[i]).balanceOf(address(this));
    }

    // tokens are exitted to feeCollector
    crp.exitPool(_amount, minTokenOut);

    IERC20 tokenInterface;
    uint256 tokenBalanceToTransfer;
    for (uint256 i=0; i<poolTokens.length; i++) {
      tokenInterface = IERC20(poolTokens[i]);

      tokenBalanceToTransfer = tokenInterface.balanceOf(address(this)).sub( // get the new balance of token
        feeCollectorTokenBalances[i] // subtract previous balance
      );

      if (tokenBalanceToTransfer > 0) {
        // transfer to `_toAddress` [newBalance - oldBalance]
        tokenInterface.safeTransfer(
          _toAddress,
          tokenBalanceToTransfer
        ); // transfer to `_toAddress`
      }
    }
  }

  function replaceAdmin(address _newAdmin) external override onlyAdmin {
    grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender); // caller must be admin
  }

  function getSplitAllocation() external view returns (uint256[] memory) { return (allocations); }

  function isAddressWhitelisted(address _address) external view returns (bool) {return (hasRole(WHITELISTED, _address)); }
  function isAddressAdmin(address _address) external view returns (bool) {return (hasRole(DEFAULT_ADMIN_ROLE, _address)); }

  function getBeneficiaries() external view returns (address[] memory) { return (beneficiaries); }
  function getSmartTreasuryAddress() external view returns (address) { return (beneficiaries[0]); }

  function isTokenInDespositList(address _tokenAddress) external view returns (bool) {return (depositTokens.contains(_tokenAddress)); }
  function getNumTokensInDepositList() external view returns (uint256) {return (depositTokens.length());}

  function getDepositTokens() external view returns (address[] memory) {
    uint256 numTokens = depositTokens.length();

    address[] memory depositTokenList = new address[](numTokens);
    for (uint256 index = 0; index < numTokens; index++) {
      depositTokenList[index] = depositTokens.at(index);
    }
    return (depositTokenList);
  }
}
