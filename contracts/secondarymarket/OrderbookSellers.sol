pragma solidity 0.6.2;

contract OrderbookSellers{

  mapping(address => uint256) public askbids;
  mapping(address => address) _nextSellerBid;
  uint256 public listSizeSell;
  address public constant GUARD = address(1);
  uint256 public totalAmountSellBook = 0;
  

  constructor() public {
    _nextSellerBid[GUARD] = GUARD;
  }

  function addNFTAskOrder(address seller, uint256 ask_price) public {
    require(_nextSellerBid[seller] == address(0));
    address index = _findIndex(ask_price);
    askbids[seller] = ask_price;
    _nextSellerBid[seller] = _nextSellerBid[index];
    _nextSellerBid[index] = seller;
    listSizeSell++;
    totalAmountSellBook+=ask_price;
  }

  function increaseAskBid(address seller, uint256 ask_price_increase) public {
    totalAmountSellBook+=ask_price_increase;
    updateQuote(seller, askbids[seller] + ask_price_increase);
  }

  function reduceAskBid(address seller, uint256 ask_price) public {
    totalAmountSellBook-=ask_price;
    updateQuote(seller, askbids[seller] - ask_price);
  }

  function updateQuote(address seller, uint256 newAsk) public {
    require(_nextSellerBid[seller] != address(0));
    address prevSeller = _findPrevSeller(seller);
    address nextSeller = _nextSellerBid[seller];
    uint256 diff = newAsk - askbids[seller];
    if(_verifyIndex(prevSeller, newAsk, nextSeller)){
      totalAmountSellBook+=diff;
      askbids[seller] = newAsk;
    } else {
      totalAmountSellBook+=diff;
      removeSeller(seller);
      addNFTAskOrder(seller, newAsk);
    }
  }

  function removeSeller(address seller) public {
    require(_nextSellerBid[seller] != address(0));
    address prevSeller = _findPrevSeller(seller);
    _nextSellerBid[prevSeller] = _nextSellerBid[seller];
    _nextSellerBid[seller] = address(0);
    totalAmountSellBook-=askbids[seller];
    askbids[seller] = 0;
    listSizeSell--;
  }

  function getLowestAsks(uint256 k) public view returns(address[] memory) {
    require(k <= listSizeSell);
    address[] memory sellerLists = new address[](k);
    address currentAddress = _nextSellerBid[GUARD];
    for(uint256 i = 0; i < k; ++i) {
      sellerLists[i] = currentAddress;
      currentAddress = _nextSellerBid[currentAddress];
    }
    return sellerLists;
  }

  function averagePriceInCent() public view returns(uint256) {
      return (totalAmountSellBook / listSizeSell) * 100;
  }

  function _verifyIndex(address prevSeller, uint256 newValue, address nextSeller)
    internal
    view
    returns(bool)
  {
    return (prevSeller == GUARD || askbids[prevSeller] <= newValue) && 
           (nextSeller == GUARD || newValue < askbids[nextSeller]);
  }

  function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextSellerBid[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextSellerBid[candidateAddress];
    }
  }

  function _isPrevSeller(address seller, address prevSeller) internal view returns(bool) {
    return _nextSellerBid[prevSeller] == seller;
  }

  function _findPrevSeller(address seller) internal view returns(address) {
    address currentAddress = GUARD;
    while(_nextSellerBid[currentAddress] != GUARD) {
      if(_isPrevSeller(seller, currentAddress))
        return currentAddress;
      currentAddress = _nextSellerBid[currentAddress];
    }
    return address(0);
  }
} 