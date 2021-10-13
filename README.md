# GET Protocol - General Smart Contract Specification - getNFT
Contract overview and definition of the GET Protocols getNFTs. Allowing P2P trading of smart tickets, lending and more. In this repo the conceptual and achritectual documentation of the GET Protocol is maintained and updated. The code in this repo is only a small part of the tech stack of the GET Protocol.

---

## Deployed contracts - Mainnet production

Proxy contract addresses (remain unchanged regardless)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| Proxy_AccessControlGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x3b4edAE1F2E1971C716a07FDAf65aFb144141B51#code) |
| Proxy_eventMetadataStorage | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0xcDA348fF8C175f305Ed8682003ec6F8743067f79#code) |
| Proxy_economicsGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x7D25EA705A30Dd1A7F449A3540869bd102dE1a37#code) |
| Proxy_baseGETNFT | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x308e44cA2153C61103b0DC67Fd038De650912b73#code) |
| Proxy_ERC721UpgradeableGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x2055244A719229d669488E389388f2d653A452F4#code) |
| Proxy_ticketFuelDepot | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x41E0d1701baDD8F876Df8c35C5D450cFEeA0AB6d#code) |
| Proxy_getEventFinancing | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x2D2D60864ac782A45cF6f53b03bbF7A29Dfede44#code) |
| MockGET | ERC20 | [Polygonscan Mainnet](https://polygonscan.com/address/0xE35357E513f0Ea7FA344De35bF13eC0c06ECCaA5#code) |

Implementation contracts (can be replaced/upgraded)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| AccessControlGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xe01a0d6d0cdf86a15101feab62606dfd0d20042d#code) |
| eventMetadataStorage | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x0230078d740b2432d7b29e4a947711cb7dd35159#code) |
| economicsGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x62d0e96fd9b4e22f71cf2d2b930ecd142527c5ee#code) |
| baseGETNFT | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x308e44cA2153C61103b0DC67Fd038De650912b73#code) |
| ERC721UpgradeableGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x3e5540e847c019ffec7b1a4957cd4026c74a5865#code) |
| ticketFuelDepot | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xbd0a1d995aa3b8462542ab00941b9230dc1d381c#code) |
| getEventFinancing | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xe276ed1a4b9b7b433bbfb9ce64083da8c77050af#code) |

## Deployed contracts - Testnet / Mumbai

Proxy contract addresses (remain unchanged regardless)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| Proxy_AccessControlGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xadda233d0fEcFf06b21A481fE55F60A1e9d136FA#code) |
| Proxy_eventMetadataStorage | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x84418467496606DAA7fBc3ED072e1F5519024368#code) |
| Proxy_economicsGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xBdc7b995275a640784b50A645caccA7464759774#code) |
| Proxy_baseGETNFT | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x10fAC2847b8F4f85CFd62e796aB091b3a435325F#code) |
| Proxy_ERC721UpgradeableGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x323a5435A2421f03a708031Db0331086Ac4C4319#code) |
| Proxy_ticketFuelDepot | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x72f4aB5A174F59a290A52Ff98D05fEA88B743F0e#code) |
| Proxy_getEventFinancing | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x6059C10b9b0f86ACade749B8Fc563b4B4a2D8bb7#code) |
| MockGET | ERC20 | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x0959edbA88525E4629bD3c7053eB4cC782D6D804#code) |

Implementation contracts (can be replaced/upgraded)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| AccessControlGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/) |
| eventMetadataStorage | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x42e3af666c811be81ecf303a3fe794a71bac40a2#code) |
| economicsGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xbcf00feaea918c1578313e99433b7a8aa3fb8dad#code) |
| baseGETNFT | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xdbcd400f3e8f909c3f5af9ccdbcf7a834bb2c73f#code) |
| ERC721UpgradeableGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x77a14401a4cd7f76b2df7988c0e4c28440da1f9f#code) |
| ticketFuelDepot | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xe715b5dd2c8c4ea49a31f98ce98755638e8b946b#code) |
| getEventFinancing | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xf494816a6db68ca17dc2d049559cb06d86cc291e#code) |

---

**High Level Overview GET Protocol**
![Diagram Overview](./markdown_images/overview_layers.png)
Custody (the HD wallet infrastructure) and engine (the tx processing and logic board) are still closed-source. This repository is the asset_factory. At the moment the GET Protocol is issuing getNFT assets on the blockchains Ropsten (Ethereum Testnet), BSC Testnet (Binance Smart Chain) and for all Korean ticketing and services the Klaytn Blockchain (mainnet).

## Definition of a getNFT asset
The GET Protocol offers a toolsel to make (event) tickets interoperable, liquid and securitizable. Tickets are digital rights of entry. Hence. the crypto address that owns a getNFT at the moment the event scanning starts, is the entity that will be able to use the ticket to enter the venue. 

The getNFT is thus a transferrable digital right. These tickets/getNFTs will have a value on the secondary market. The contract logic described in the repo, allow for getNFTs to be traded and exchanged between Ethereum/Klaytn/BSC addresses/users.

getNFT is compliant with the ERC721 standard. getNFT adopts the following interfaces:
- IERC721
- IERC721Metadata
- IERC721Enumerable
- IERC721Receiver

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


## API Documentation for ticketIssuers (Ticketeers)
The GET Protocol offers for ticketIssuers an API interface to pass on the activity on their systems to the blockchain twin of the issued tickets. Provided links below detail the API interface for ticketeers:

- [GETProtocol Documentation](https://docs.get-protocol.io/)
