# GET Protocol - General Smart Contract Specification - getNFT
Contract overview and definition of the GET Protocols getNFTs. Allowing P2P trading of smart tickets, lending and more. In this repo the conceptual and achritectual documentation of the GET Protocol is maintained and updated. The code in this repo is only a small part of the tech stack of the GET Protocol.

## API Documentation for ticketIssuers (Ticketeers)
The GET Protocol offers for ticketIssuers an API interface to pass on the activity on their systems to the blockchain twin of the issued tickets. Provided links below detail the API interface for ticketeers:

- [GETProtocol Documentation](https://docs.get-protocol.io/)

---

# GET Protocol Refactored Contracts
In this readme the functions and event emitted will be detailed.  

### BaseGET (proxy)
Main contact point for interactions regarding NFTs. Stores the metadata (price, strings etc) of the ticket NFTs. Contract does NOT store/register whom owns an NFT as this is done by the getERC721 proxy contract. 

### **primarySale:** 
Issuance of getNFT to address destinationAddress.\


```javascript
    function primarySale(
        address _destinationAddress, 
        address _eventAddress, 
        uint256 _primaryPrice,
        uint256 _basePrice,
        uint256 _orderTime,
        bytes32[] calldata _ticketMetadata
    ) external onlyRelayer {
```

Events emitted: `PrimarySaleMint`
```javascript
    event PrimarySaleMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 basePrice
    );
```

---


### **secondaryTransfer** 
Secondary market/P2P getNFT ownership change.\


```javascript
    function secondaryTransfer(
        address _originAddress, 
        address _destinationAddress,
        uint256 _orderTime,
        uint256 _secondaryPrice) external onlyRelayer {
```


Events emitted: `SecondarySale`
```javascript
    event SecondarySale(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 resalePrice
    );
```

---

### **scanNFT** 
Validation of getNFT by scanner/issuer. Does not make NFT claimable.\

```javascript
    function scanNFT(
        address _originAddress,
        uint256 _orderTime
    ) external onlyRelayer {
```

Events emitted: `IllegalScan` or `TicketScanned`

```javascript
    event TicketScanned(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
```

or

```javascript
    event IllegalScan(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
```

---


### **invalidateAddressNFT** 
Invalidates getNFT (makes unscannable, unclaimable).\
```javascript
    function invalidateAddressNFT(
        address _originAddress, 
        uint256 _orderTime) external onlyRelayer {
```

Events emitted: `TicketInvalidated`
```javascript
    event TicketInvalidated(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    ); 
```

---

### **claimgetNFT** 
Claims an NFT from custody controlled EOA to an external EOA\

```javascript
    function claimgetNFT(
        address _originAddress, 
        address _externalAddress,
        uint256 _orderTime) external onlyRelayer {
```


Events emitted: `NftClaimed`
```javascript
    event NftClaimed(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
```

---

### **checkIn** 
Checks in NFT, makes the asset CLAIMABLE. Drains the GET in the backpack to the DAO.


```javascript
    function checkIn(
        address _originAddress,
        uint256 _orderTime
    ) external onlyRelayer {
```


Events emitted: `CheckedIn`
```javascript
    event CheckedIn(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
```

or 

```javascript
    event NftClaimed(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );
```

---

### **collateralMint** 


```javascript
    function collateralMint(
        address _basketAddress,
        address _eventAddress, 
        uint256 _primaryPrice,
        bytes32[] calldata _ticketMetadata
    ) external onlyFactory {
```


Events emitted: `CollateralizedMint`
```javascript
    event CollateralizedMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime,
        uint256 basePrice
    );
```

---

## EventMetadataStorage (proxy)
Stores the metadata of the events on the GET Protocol.

```javascript
    function registerEvent(
      address _eventAddress,
      address _integratorAccountPublicKeyHash,
      string memory _eventName, 
      string memory _shopUrl,
      string memory _imageUrl,
      bytes32[4] memory _eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] memory _eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool _setAside, // -> false = default
      bytes32[] memory _extraData,
      bool _isPrivate
      ) public onlyRelayer {
```


Events emitted: `NewEventRegistered`
```javascript
    event NewEventRegistered(
      address indexed eventAddress,
      uint256 indexed getUsed,
      string eventName,
      uint256 indexed orderTime
    );
```

---

## economicsGET (proxy)
Contract holds balances of ticketeers. Fuels the NFTs in the depot contract. 

### **setDynamicRateStruct** ONLYADMIN
loads the NFT balance with GET in its backpack (called by economicsGET)\

```javascript
    function setDynamicRateStruct(
        address _relayerAddress,
        uint32[12] calldata dynamicRates
    ) external onlyAdmin {
```

Events emitted: `RelayerConfiguration`
```javascript
    event RelayerConfiguration(
        address relayerAddress,
        uint32[12] dynamicRates
    );
```


---


### **clearDynamicRateStruct** ONLYADMIN
loads the NFT balance with GET in its backpack (called by economicsGET)\

```javascript
    function clearDynamicRateStruct(
        address _relayerAddress
    ) external onlyAdmin {
```

Events emitted: `RelayerConfigurationCleared`
```javascript
    event RelayerConfigurationCleared(
        address relayerAddress
    );
```


---


### **_calculateNewAveragePrice** INTERNAL
charges the baseRateGlobal rate as set in the contract, decreasing the backpack balance\

```javascript
    function _calculateNewAveragePrice(
        uint256 _topUpAmount, 
        uint256 _priceGETTopUp, 
        address _relayerAddress
    ) internal returns(uint256) {
```

Events emitted: `AveragePriceUpdated`
```javascript
    event AverageSiloPriceUpdated(
        address relayerAddress,
        uint256 oldPrice,
        uint256 newPrice
    );
```

---

### **topUpRelayer:**

```javascript
    function topUpRelayer(
            uint256 _topUpAmount,
            uint256 _priceGETTopUp,
            address _relayerAddress
        ) external onlyAdmin nonReentrant returns(uint256) {
```

Events emitted: `RelayerToppedUp`
```javascript
    event RelayerToppedUp(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    );
```

---

### **swipeDepotBalance:** 
moves the accumulated GET from the depot to the DAO treasury

```javascript
    function swipeDepotBalance() external nonReentrant returns(uint256) {
        require(collectedDepot > 0, "NOTHING_TO_SWIPE");
```

Events emitted: `DepotSwiped`
```javascript
    event DepotSwiped(
        address feeCollectorAddress,
        uint256 balance
    );
```


---

### **emptyBackpackBasic:** 

```javascript
    function emptyBackpackBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {
```

