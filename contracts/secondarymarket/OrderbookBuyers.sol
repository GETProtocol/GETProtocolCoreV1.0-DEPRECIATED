pragma solidity 0.6.2;

contract OrderbookBuyers{

  mapping(address => uint256) public buybids;
  mapping(address => address) _nextBuyerBid;
  uint256 public listSizeBuy;
  address public constant GUARD = address(1);
  uint256 public totalAmountBuyBook = 0;

  constructor() public {
    _nextBuyerBid[GUARD] = GUARD;
  }

  function addNFTBidOrder(address buyer, uint256 bid_price) public {
    require(_nextBuyerBid[buyer] == address(0));
    address index = _findIndex(bid_price);
    buybids[buyer] = bid_price;
    _nextBuyerBid[buyer] = _nextBuyerBid[index];
    _nextBuyerBid[index] = buyer;
    listSizeBuy++;
    totalAmountBuyBook+=bid_price;
  }

  function increaseBuyBid(address buyer, uint256 bid_price) public {
    totalAmountBuyBook+=bid_price;
    updateQuote(buyer, buybids[buyer] + bid_price);
  }

  function reduceBuyBid(address buyer, uint256 bid_price) public {
    totalAmountBuyBook-=bid_price;
    updateQuote(buyer, buybids[buyer] - bid_price);
  }

  function updateQuote(address buyer, uint256 newBid) public {
    require(_nextBuyerBid[buyer] != address(0));
    address prevBuyer = _findPrevBuyer(buyer);
    address nextBuyer = _nextBuyerBid[buyer];
    uint256 diff = newBid - buybids[buyer];
    if(_verifyIndex(prevBuyer, newBid, nextBuyer)){
      totalAmountBuyBook+=diff;
      buybids[buyer] = newBid;
    } else {
      totalAmountBuyBook+=diff;
      removeBuyer(buyer);
      addNFTBidOrder(buyer, newBid);
    }
  }

  function removeBuyer(address buyer) public {
    require(_nextBuyerBid[buyer] != address(0));
    address prevBuyer = _findPrevBuyer(buyer);
    _nextBuyerBid[prevBuyer] = _nextBuyerBid[buyer];
    _nextBuyerBid[buyer] = address(0);
    totalAmountBuyBook-=buybids[buyer];
    buybids[buyer] = 0;
    listSizeBuy--;
  }

  function getHighestBids(uint256 k) public view returns(address[] memory) {
    require(k <= listSizeBuy);
    address[] memory buyerLists = new address[](k);
    address currentAddress = _nextBuyerBid[GUARD];
    for(uint256 i = 0; i < k; ++i) {
      buyerLists[i] = currentAddress;
      currentAddress = _nextBuyerBid[currentAddress];
    }
    return buyerLists;
  }

  function averagePriceInCent() public view returns(uint256) {
      return (totalAmountBuyBook / listSizeBuy) * 100;
  }

  function _verifyIndex(address prevBuyer, uint256 newValue, address nextBuyer)
    internal
    view
    returns(bool)
  {
    return (prevBuyer == GUARD || buybids[prevBuyer] >= newValue) && 
           (nextBuyer == GUARD || newValue > buybids[nextBuyer]);
  }

  function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextBuyerBid[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextBuyerBid[candidateAddress];
    }
  }

  function _isPrevBuyer(address buyer, address prevBuyer) internal view returns(bool) {
    return _nextBuyerBid[prevBuyer] == buyer;
  }

  function _findPrevBuyer(address buyer) internal view returns(address) {
    address currentAddress = GUARD;
    while(_nextBuyerBid[currentAddress] != GUARD) {
      if(_isPrevBuyer(buyer, currentAddress))
        return currentAddress;
      currentAddress = _nextBuyerBid[currentAddress];
    }
    return address(0);
  }
} 