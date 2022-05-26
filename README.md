
# GET Protocol Contracts (DEPRECIATED / OLD VERSION)
Technical documentation coverting the GET Protocols contracts. Issuing getNFT (digital twins of event tickets). 

Note: The contracts in this repo represent the OLD NFT minting contracts. Our new code base is currently undergoing its final checks. The code in this repo is NOT representitive of GET Protocols smart contract stack (regarding both ticketing as event financing). 

## Deployed Contracts 
In the tables the address of protocols contracts are detailed. 

## Production Contracts (Polygon Mainnet)
Take note these are proxy addresses, they only contain storage and no implememntation logic. See Open Zeppelin transparent proxy pattern.
| Name | Contract type | Address |
| ------ | ------ | ------ |
| Proxy AccessControlGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x3b4edAE1F2E1971C716a07FDAf65aFb144141B51#code) |
| Proxy EventMetadataStorage | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x08C2aF3F01A36AD9F274ccE77f6f77cf9aa1dfC9#code) |
| Proxy EconomicsGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x07faA643ad0eE4ee358d5E101573A5fdfBEcD0a9#code) |
| Proxy BaseGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0xbce1b23c7544422f1E2208d29A6A3AA9fAbAB250#code) |
| Proxy ERC721UpgradeableGET | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0x2055244A719229d669488E389388f2d653A452F4#code) |
| Proxy GetEventFinancing | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0xD043857bE3d639E6aE7F2E8994Ad1917EB410CfF#code) |
| Proxy GETProtocolConfiguration | Proxy | [Polygonscan Mainnet](https://polygonscan.com/address/0xdDBD230d225FB0468D2Fd5fc905eA92a703ed4be#code) |
| Polygon GET (bridged from ETH GET) | ERC20 | [Polygonscan Mainnet](https://polygonscan.com/address/0xdb725f82818de83e99f1dac22a9b5b51d3d04dd4#code) |

---

### Playground Contracts (Polygon Testnet - Mumbai)
This is a testnet enviroment used by integrators and the development team.

Proxy contract addresses (remain unchanged regardless)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| Proxy AccessControlGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xadda233d0fecff06b21a481fe55f60a1e9d136fa#code) |
| Proxy EventMetadataStorage | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x3E1414554Eb69BF633D56d7CfFaec2b6F2593f61#code) |
| Proxy EconomicsGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x4585467f3bc6A78F4Ebb02F8A212A66efb4C27D6#code) |
| Proxy BaseGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x265a8aD18560022f6933F52a50E9DC9456EF2283#code) |
| Proxy ERC721UpgradeableGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x323a5435a2421f03a708031db0331086ac4c4319#code) |
| Proxy ConfigurationGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xeE7f7AA68e30fd5bD864719E42E65F11DC6ba526#code) |
| Proxy GetEventFinancing | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xA817aDda20df5F0568e20dA6eB5eF01d22977b78#code) |
| MockGET | ERC20 | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xCdB67b3309F379b9F9b9F87E1E3147660C38E199#code) |

---

### Testing Contracts (Polygon Testnet - Mumbai)
This is a testnet enviroment used by integrators and the development team. 
Proxy contract addresses (remain unchanged regardless)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| Proxy AccessControlGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x90a577Ce2352D79F9fC2F49aDAb8A43DCE88B1d8#code) |
| Proxy EventMetadataStorage | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x1c9a79D553ABE5D52c64BD5F1007C47DBCcC21c5#code) |
| Proxy EconomicsGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x5c26C062C74Cec95Bb155DE172EdAd3dC02713cc#code) |
| Proxy BaseGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x1c7a119c851DE77DD9A19b4a629861Ec03929f06#code) |
| Proxy ERC721UpgradeableGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xC6da03A43EC0415695E4Ec46B58fD529d886FAd1#code) |
| Proxy ConfigurationGET | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xF89Ea661259001e910Dd11E8d0FDc9A22a74e913#code) |
| Proxy GetEventFinancing | Proxy | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x39A21d9D426AB41b53b542408A94320C3F646a44#code) |
| MockGET | ERC20 | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x0E8dAa6bAad9fa71e921cDF5158C13a2F1B0f283#code) |

---

## Key Protocol Addresses  

#### GET Protocol Whitelabel address(es) - WL
relayerAddress (1): 0x383F07EccE503801F636Ad455106e270748bdE05
BufferAddress WL: 0xbC0A62565b48258665b9cee793af87C93a22A49E

#### YourTicketProvider address(es) - YTP
relayerAddress (1): 0xb9F77e8FE9AEf5df3A4C3c465B9D88423e41F41a
BufferAddress YTP: 0x0Eb7C00C78BFFefa65eB01d92D3778bDe630381B

#### DAOTreasury Contract
Gnosis multi sig address: 0x4E242E831eE532AE39E626D254e5a718270dd75B
[The Gnosis multisig is deployed on Polygon blockchain.](https://mumbai.polygonscan.com/address/0x4E242E831eE532AE39E626D254e5a718270dd75B#code)


---

#### Key Protocol Addresses Playground and Testing
Relayer 1 Playground: 0xEA7DFF0629474f9aAC107e01FA563c62498C90Fd
Relayer 2 Playground: 0x492f5C2B40F22a21E1dfC91fde7e1Be884faA497

Bufferaddress relayer 1 - Playground:  0x441ca9c552809863B719b7a780C67250F0DD20eD
Bufferaddress relayer 2 - Playground: 0x779Ae6498c27b572a8f6A9B9432299612D3331FB

#### Testing - Token economic addresses 

Relayer 1 Testing: 0x35D59a290b08D2081441922aA9D4A36a9dd83dCA
Relayer 2 Testing: 0x5400249158F83309AFCd8210ce0c995dB0B16E25

Bufferaddress relayer 1 Testing:  0x441ca9c552809863B719b7a780C67250F0DD20eD
Bufferaddress relayer 2 Testing:  0x779Ae6498c27b572a8f6A9B9432299612D3331FB

---


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

### **isNFTSellable (VIEW)** 
Returns if a NFT owned by a certain address can be resold. 
```javascript
    function isNFTSellable(
        uint256 _nftIndex,
        address _originAddress
    ) public view returns(bool _sell) {
```

### **ticketMetadataAddress (VIEW)** 
Returns the metadata stored in an NFT.
```javascript
    function ticketMetadataAddress(
        address _originAddress)
      external view returns (
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _salePrices,
          TicketStates _state
      )
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

## EconomicsGET (proxy)
Contract holds the GET balances and on-chain charging configuration of ticketeers(both whitelabels as digital twins). Fuels the NFTs in the depot contract. 

### **topUpRelayerFromBuffer:** 
Charge GET to the ticketeer silo in the economics contract.

```javascript
    function topUpRelayerFromBuffer(
            uint256 _topUpAmount,
            uint256 _priceGETTopUp,
            address _relayerAddress
        ) external onlyAdmin nonReentrant onlyConfigured(_relayerAddress) returns(uint256) {
```

Events emitted: `RelayerToppedUpBuffer`
```javascript
    event RelayerToppedUpBuffer(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    );
```

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

### **setRelayerBuffer:**  ONLYADMIN

```javascript
    function setRelayerBuffer(
        address _relayerAddress,
        address _bufferAddressRelayer
    ) external onlyAdmin {
```

Events emitted: `RelayerBufferMapped`
```javascript
    event RelayerBufferMapped(
        address relayerAddress,
        address bufferAddressRelayer
    );
```


### **clearDynamicRateStruct** ONLYADMIN

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


### **_calculateNewAveragePrice** INTERNAL

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

### **fuelBackpackTicket **

```javascript
    function fuelBackpackTicket(
        uint256 _nftIndex,
        address _relayerAddress,
        uint256 _basePrice
        ) external onlyFactory onlyConfigured(_relayerAddress) returns (uint256) 
```


### **swipeDepotBalance ** 
Moves the accumulated GET from the depot to the DAO treasury.

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

### **emptyBackpackBasic ** 
Moves all the GET from the backpack to the depot. 

```javascript
    function emptyBackpackBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {
```

### **chargeTaxRateBasic **

```javascript
    function chargeTaxRateBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {
```


### **chargeTaxRateBasic **

```javascript
    function chargeTaxRateBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {
```


### **balanceRelayerSilo VIEW **

```javascript
    function balanceRelayerSilo(
        address _relayerAddress
    ) external view returns (uint256) 
```


### **checkRelayerConfiguration VIEW **

```javascript
    function checkRelayerConfiguration(
        address _relayerAddress
    ) external view returns (bool) {
```


### **chargeTaxRateBasic VIEW **

```javascript
    function chargeTaxRateBasic(
        uint256 _nftIndex
    ) external onlyFactory returns(uint256) {
```


### **valueRelayerSilo VIEW **

```javascript
    function valueRelayerSilo(
        address _relayerAddress
    ) public view returns(uint256) {
```


### **estimateNFTMints VIEW **

```javascript
    function estimateNFTMints(
        address _relayerAddress
    ) external view returns(uint256) {
```


### **viewRelayerRates VIEW **

```javascript
    function viewRelayerRates(
        address _relayerAddress
    ) external view returns (DynamicRateStruct memory) 
```


### **viewRelayerFactor VIEW **

```javascript
    function viewRelayerFactor(
        address _relayerAddress
    ) external view returns (uint256) {
```

### **viewRelayerGETPrice VIEW **

```javascript
    function viewRelayerGETPrice(
        address _relayerAddress 
    ) external view returns (uint256) {
```


### **viewBackPackBalance VIEW **

```javascript
    function viewBackPackBalance(
        uint256 _nftIndex
    ) external view returns (uint256) {
```


### **viewBackPackValue VIEW **

```javascript
    function viewBackPackValue(
        uint256 _nftIndex,
        address _relayerAddress
    ) external view returns (uint256) {
```

### **viewDepotBalance VIEW **

```javascript
    function viewDepotBalance() external view returns(uint256) {
```

### **viewDepotValue VIEW **

```javascript
    function viewDepotValue() external view returns(uint256) {
```

### **viewBufferOfRelayer VIEW **

```javascript
    function viewBufferOfRelayer(
        address _relayerAddress
    ) public view returns (address) {
```


---


## GETProtocolConfigurationn (proxy)
The Configuration contract contains all the global protocol variables and configurations. 

### **setAllContractsStorageProxies ** 


```javascript
    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external onlyOwner {
```



### **setAccessControlGETProxy ** 

```javascript
    function setAccessControlGETProxy(
        address _access_control_proxy
        ) external onlyOwner {
```
Events emitted: `UpdateAccessControl`
```javascript
event UpdateAccessControl(address _old, address _new);
```

### **setBASEProxy ** 

```javascript
    function setBASEProxy(
        address _base_proxy) external onlyOwner {
```

Events emitted: `UpdatebaseGETNFT`
```javascript
event UpdatebaseGETNFT(address _old, address _new);
```

### **setMetaProxy ** 

```javascript
    function setMetaProxy(
        address _metadata_proxy) external onlyOwner {
```

Events emitted: `UpdateMetdata`
```javascript
event UpdateMetdata(address _old, address _new);
```

### **setERC721Proxy ** 

```javascript
    function setERC721Proxy(
        address _erc721_proxy) external onlyOwner {
```

Events emitted: `UpdateERC721`
```javascript
event setERC721Proxy(address _old, address _new);
```


### **setMetaProxy ** 

```javascript
    function setMetaProxy(
        address _metadata_proxy) external onlyOwner {
```

Events emitted: `setMetaProxy`
```javascript
event setMetaProxy(address _old, address _new);
```

### **setFinancingProxy ** 

```javascript
    function setFinancingProxy(
        address _financing_proxy) external onlyOwner {
```

Events emitted: `UpdateFinancing`
```javascript
event UpdateFinancing(address _old, address _new);
```

### **setGETUSD ** 

```javascript
    function setGETUSD(
        uint256 _newGETUSD
    ) external onlyOwner {
```

Events emitted: `UpdateGETUSD`
```javascript
event UpdateGETUSD(uint256 _old, uint256 _new);
```

### **setBasicTaxRate ** 

```javascript
    function setBasicTaxRate(
        uint256 _basicTaxRate
    ) external onlyOwner {
```

Events emitted: `UpdateBasicTaxRate`
```javascript
event UpdateBasicTaxRate(uint256 _old, uint256 _new);
```
