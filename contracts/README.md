
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

**topUp:** 
top up the GET fuel balance of a ticketeer

```javascript
```

Events emitted: ``
```javascript
```


**fuelBackpack:** 
loads the NFT balance with GET in its backpack (called by economicsGET)\

```javascript
```

Events emitted: ``
```javascript
```


**chargeProtocolTax:**
charges the baseRateGlobal rate as set in the contract, decreasing the backpack balance\

```javascript
```

Events emitted: ``
```javascript
```

**swipeCollected:** moves the accumulated GET from the depot to the DAO treasury

```javascript
```

Events emitted: ``
```javascript
```


<!-- ___

## 3. Contract Modifiers / AccessControl
To manage acces the contract uses the RoleManager modules from open zeppelin. 

AccessControlGET defines the following roles in: AccessControlGET.sol\

```
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");
```

---

#### 1. Core team / Admin - modifier: onlyAdmin
Controlled by GET Protocol team and core developers. Used for configuration, global variable declaration (pricing) and other edit tasks.  

##### Role abilities 
**Allowed:** Set contract variables, set pricing, add/remove addresses to access control,freeze non money handling processes\
**NOT Allowed** Withdraw crypto from contracts, handle stable coins, mint NFTs, register events, freeze money handling processes

##### Key security / storage 
Preferred to be a ledger or hardware wallet. Only when custody handles the key is it allowed to be a 'hot key' (meaning not in a hardware wallet). **NOT ALLOWED TO HAVE AN ADMIN KEY IN METAMASK OR AS A NAKED PRIVAYE KEY IN A CODE FILE.**

---

#### 2. ticketeer / integrators - modifier: onlyRelayer
On chain identity of ticketing companies using the protocol (integrators). This address signs all transactions issuing and changing the state of assets issued by the ticketeer. These addresses are referred to in the code as **relayerAddresss**.

##### onlyRelayer abilities 
**Allowed:** Mint their NFTs, scan, invalidate their NFTs, store metadata in getNFTs \
**NOT Allowed:**  Set variables, handle cryptos and stables, pause contracts, touch NFTs not issued by ticketeer \

##### Key security / storage 
As this key will be constantly used to sign transactions, it will always be stored in a server (in encryped form in Custody).

Remarks / good to know:\
- _ticketeers or integrators could have multiple relayerAddresses representing their tickets_ \
- _In the first versions of the GET Protocol contracts these addresses will be managed and maintained by the GET Protoocol foundation._

---

#### 3. God mode - modifier: onlyGovernance
This key or contract is able to withdraw funds, pause the system and change key configurations possibly leading into financial loss.

##### Role abilities 
**Allowed:** Pull funds, finalize money handling contracts, freeze system\
**NOT Allowed:**  Mint NFTs, register events, change configurations, change variables, deploy proxies

##### Key security / storage 
Ideally this contract/role is controlled by a DAO governance module that allows token holders to vote on execution. However in the current state of the protocol this is not feasable or desirable (requires very serious goverance infra and involvement). Therefor this role will evolve in how it is stored and handled. 

An example of such a timeline is is shown below, obviously this is subject to lots of change.

1. Key stored in ledger held by core team (only 1 or 2 ledgers)
2. 2/6 Multi-sig controlled held by core team members
3. 3/8 Multi-sig controlled by half core team, 1 governance, 1 external dev, 1 external known thoughtleader (like Andre Cronye, Banteg, Chris Black etc)
4. DAO controlled contract (Compound) + a 5/6 multi-sig held by community assigned governers for emergency procedures


---

#### 4. GET Protocol Contracts - modifier: onlyFactory
GET Protocol contracts often call functions in other protocol contracts. 

##### Role abilities 
**Allowed:** mint NFTs, store metadata, change states, request internal balance or ledger changes\
**NOT Allowed:** pause contracts, pull funds, change global variables, deploy and initialize contracts   

##### Key security / storage 
This modifier class registers what addresses are protocol contracts and can be trusted. Therefor we can say that this role doesn't have a private key as they can only be accessed by calling a contracts function and having this function call a other contract.

**POTENTIAL DANGER/VECTOR - Example if an is able to take control of the implementation contracts deployment of one of the GET proxies, this entity could write functions calling any function in other GET Protocol contracts that are protected by this modifier. THis isn't a viable attack as it would require the compromise of a admin key, but good to keep in mind that this is how modifier and proxies work** 

___
 -->



<!-- ## Deployed contracts - Mainnet production

### Proxy contract addresses (remain unchanged regardless)
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



### Implementation contracts (can be replaced/upgraded)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| AccessControlGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xe01a0d6d0cdf86a15101feab62606dfd0d20042d#code) |
| eventMetadataStorage | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x0230078d740b2432d7b29e4a947711cb7dd35159#code) |
| economicsGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x62d0e96fd9b4e22f71cf2d2b930ecd142527c5ee#code) |
| baseGETNFT | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x308e44cA2153C61103b0DC67Fd038De650912b73#code) |
| ERC721UpgradeableGET | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0x3e5540e847c019ffec7b1a4957cd4026c74a5865#code) |
| ticketFuelDepot | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xbd0a1d995aa3b8462542ab00941b9230dc1d381c#code) |
| getEventFinancing | Implementation | [Polygonscan Mainnet](https://polygonscan.com/address/0xe276ed1a4b9b7b433bbfb9ce64083da8c77050af#code) |

***

## Deployed contracts - Testnet / Mumbai

###Proxy contract addresses (remain unchanged regardless)
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


### Implementation contracts (can be replaced/upgraded)
| Name | Contract type | Address |
| ------ | ------ | ------ |
| AccessControlGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/) |
| eventMetadataStorage | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x42e3af666c811be81ecf303a3fe794a71bac40a2#code) |
| economicsGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xbcf00feaea918c1578313e99433b7a8aa3fb8dad#code) |
| baseGETNFT | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xdbcd400f3e8f909c3f5af9ccdbcf7a834bb2c73f#code) |
| ERC721UpgradeableGET | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0x77a14401a4cd7f76b2df7988c0e4c28440da1f9f#code) |
| ticketFuelDepot | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xe715b5dd2c8c4ea49a31f98ce98755638e8b946b#code) |
| getEventFinancing | Implementation | [Polygonscan Mumbai](https://mumbai.polygonscan.com/address/0xf494816a6db68ca17dc2d049559cb06d86cc291e#code) |

___ -->



<!-- ___

### 1. getNFT Asset Specification
The getNFT contract processes all the requests from the engine. The primary rol of the getBASENFT engine & its contracts is to manage the exchange/trading of getNFTs as instructed by the `integrator`. 

_Note: integrators/ticketissuers do not need to understand or study or adopt this data specification. The getNFT engine will handle all data and convert it in the right format for the getNFT smart contract to process._

The ticketing usecase requires several custom variables and datafields. The tables below will break down these variables per metadata category. 

###### 1 A. Identity variables specification 
Data fields on ownership of getNFTs. 

| Var | Description | Type  |
| ------ | ------ | ------ |
| *destinationAddress* | The to-be/intended future owner of a getNFT asset. | `address` |
| *originAddress*   | The current/past owner of a getNFT asset. |   `address` |
| *ticketIssuerAddress* | The address of the ticketissuer that has issued the getNFT. | `address` |


###### 1 B. Metadata variables specification
Data fields describing metadata of getNFTs. 

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *ticketMetadata* | Data field pointing/reference set by ticketissuer (no rules set by protocol). | `string` |
| *eventAddress*   | Address of the event the getNFT asset belongs to set by custody. |   `address` |
| *statusNft* depreciated | Metadata field specifying if getNFT is scanned. True = scanned, False = unscanned.  |   `bool` |

###### 1 C. Internal variables specification 
Variables that are used internally in the getNFT contact.

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *nftIndex*   | Internal reference/pointer to the asset in the smart contract.      |   `uint256` |
| *_timestamp* | Data field pointing to a certain ticket/asset of the issuer. | `string` |
| *onlyRelayer* | Solidity modifier. Only addresses that are registered as a 'relayer' can access this func. |   `msg.sender` (address) |
| *onlyMinter* | Solidity modifier. Only addresses that are registered as a 'relaminteryer' can access this func.  |   `msg.sender` (address) |


___ -->