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

## API Documentation for ticketIssuers (Ticketeers)
The GET Protocol offers for ticketIssuers an API interface to pass on the activity on their systems to the blockchain twin of the issued tickets. Provided links below detail the API interface for ticketeers:

- [GETProtocol getNFT Interface](https://documenter.getpostman.com/view/12511061/TVYKYvVH)

- [GETProtocol getNFT Callbacks](https://documenter.getpostman.com/view/12511061/TVYKYvQo#bd4bcf88-eff9-4341-9eac-71d3f4348b5d)

It is for the public not possible to interact with these API endpoints. getNFTs owners that want to move their getNFTs and that have access to their private keys, are able to use their own wallet to interact with their assets. 

![custody overview](./markdown_images/custody_queue.png)

---

### 1. getNFT Asset Specification
The getNFT contract(ERC721_TICKETING_V2) processes all the requests from the getNFT engine. The primary rol of the getNFT engine & its contracts is to manage the exchange/trading of getNFTs as instructed by the `ticketissuer`. 

Note: integrators/ticketissuers do not need to understand or study or adopt this data specification. The getNFT engine will handle all data and convert it in the right format for the getNFT smart contract to process. 

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
| *statusNft* | Metadata field specifying if getNFT is scanned. True = scanned, False = unscanned.  |   `bool` |

###### 1 C. Internal variables specification 
Variables that are used internally in the getNFT contact.

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *nftIndex*   | Internal reference/pointer to the asset in the smart contract.      |   `uint256` |
| *_timestamp* | Data field pointing to a certain ticket/asset of the issuer. | `string` |
| *onlyRelayer* | Solidity modifier. Only addresses that are registered as a 'relayer' can access this func. |   `msg.sender` (address) |
| *onlyMinter* | Solidity modifier. Only addresses that are registered as a 'relaminteryer' can access this func.  |   `msg.sender` (address) |


---

### 2. getNFT Ownership Functions Specification
The getNFT contract manages the ownership and metadata management of event-assets on-chain. The getNFT engine (and its blockchain nodes) have access to the GET Protocol custody vault. This system holds all the HD wallets derivations of all the users in the system that prefer to have their keys managed by a specialized third party.   

**A.  primaryMint: Issuance of getNFT to address.**
This action is triggered when a ticket is sold to a fan/user. Triggering the creation of the digital twin of the ticket.

**B. secondaryTransfer: Secondary market/P2P getNFT ownership change**
This action is triggered when a ticket is resold/traded between fans.

**C. scanNFT: Validation of getNFT by scanner/issuer**
This action is triggered when a ticket is scanned validated. 

Functions A, B & C can only be called by whitelisted addresses(see section 3 of this documentation covering modifiers). If an getNFT owner wants to interact directly with their NFT, they can use the ERC721 functions (meaning, `safeTransferFrom`, `approve`, `ownerOf` etc). The getNFT is still completely compatable with the ERC271 standard, what makes a getNFT different is that it includes several 'custom' functions that allow ticketIssuers to move getNFTs as the data-base twin of the ticket changes state/hands.  

#### A1. primaryMint (OLD V0)
Mint a new getNFT to a destinationAddress(address of buyer of the getNFT). The function will return the nftIndex (uint256) of the issued getNFT. 
```javascript
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata) public onlyMinter returns (uint256) {
```

This function will emit the following event to the event-log of the GET Factory contract:   `txPrimaryMint(destinationAddress, ticketIssuerAddress, nftIndex, _timestamp)`.

The values passed in the `ticketIssuerAddress`, `eventAddress` and `ticketMetadata` are stored immutably in the metadata fields of the ERC721 asset.

![Primary NFT](./markdown_images/primarymint.png)


#### B. secondaryTransfer
If a ticket is resold to a other address this function is triggered. The getNFT custody uses a fresh wallet for each getNFT. The `originAddress` needs to be the owner of a getNFT for this function to be successful. 

```javascript
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer;
```
This function will emit the following event:  `txSecondary(originAddress, destinationAddress, getAddressOfticketIssuer(nftIndex), nftIndex, _timestamp)`.

![Primary NFT](./markdown_images/secondarymint.png)

#### C. scanNFT
Function that sets the `_nftScanned` metadata field to `true` in the getNFT. This is an immutable action. The getNFT remains transferrable after this action.

```javascript
    function scanNFT(address originAddress) public onlyRelayer;
```
This function will emit the following event:  `emit txScan(originAddress, destinationAddress, nftIndex, _timestamp);`. As of now validating a ticket is immutable. 

![Primary NFT](./markdown_images/scannft.png)

---

## 3. Contract Modifiers 
To manage acces the contract uses the RoleManager modules from open zeppelin.  
1. Minter/Admin: Set contract variables, proxy adminstration, add/remove addresses to access control etc.
2. Relayer: Mint NFFs, move NFTs, store metadata in getNFTs etc

In the first versions of the GET Protocol contracts these addresses will be managed and maintained by the GET Protoocol foundation.

---


## 4. getNFT Contract Events Emitted (Ticket Explorer)


*Events emitted by ERC721_TICKETING_V2*
```javascript
    event txPrimaryMint(address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp)
    event txScan(address originAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event doubleScan(address indexed originAddress, uint256 indexed nftIndex, indexed uint _timestamp);
```

Event log of ERC721_TICKETING_V2:
- `txPrimaryMint`: Primary market ticket sold/issued.
- `txSecondary`: Secondary market ticket traded/shared.
- `txScan`: Ticket scanned/validated.
- `doubleScan`: An already valid ticket was scanned again. 

*Events emitted by MetaDataTE*
```javascript
    event newEventRegistered(address indexed eventAddress, string indexed eventName, uint indexed _timestamp);
    event newTicketIssuerRegistered(address indexed ticketeerAddress, string indexed ticketeerName, uint indexed _timestamp);
```

Event log of MetaDataTE:
- `newEventRegistered`: New event registered in Metadata contract. 
- `newTicketIssuerRegistered`: New ticketIssuer registered in Metadata contract.
- `eventMetaDataUpdated`: TO BE ADDED / NOT YET PRESENT  IN CONTRACT - Metadata of an event was changed/updated.


---

### Deploying the contracts in this repository
WORK IN PROGRESS (commands as stated do not work yet).


```bash
# install dependencies
$ npm install

# deploy contracts (be sure to change the 'from' account in 'truffle.js')
$ truffle migrate --reset --network ganache

# start app
$ npm run dev
```


### Variables changed 
ticketeer = ticketIssuer
_ticketeerAddresss = _ticketIssuerAddresses
_ticketeerAddress = _ticketIssuerAddress
TicketeerStruct = TicketIssuerStruct
allTicketeerStructs = allTicketIssuerStructs
isTicketeer = isTicketIssuer
ticketeerAddress = ticketIssuerAddress
ticketeerAddresses = ticketIssuerAddresses
_markTicketeerAddress = _markTicketIssuerAddress
ticketeerMetaData = ticketIssuerMetadata
newTicketeer = newTicketIssuer
newTicketeerRegistered = newTicketIssuerRegistered