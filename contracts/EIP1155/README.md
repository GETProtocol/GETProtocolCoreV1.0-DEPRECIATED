
# PROCESS - Upgrade to EIP1155
Readme describing the process and progress of adding the ability to mint ERC1155 NFTs as tickets. Implementing EIP1155 will enable batch minting as well as delivering huge gas savings on a per ticket basis. The projected gas savings achieved by implementing 1155 as implemented in testing right now are around 85-95% (depending on the size of the batch).As described in the original EIP1155 standard/proposal, the standard relies on event emission as a means to store data and publically document changes. 


## Scaling ticket minting
A big chokepoint for GET in minting large amounts of tickets can be summarized by the following technical blockchain realities:
- To enable on-chain economics, tickets needs to be registered by funded and whitelisted EOA accounts. This means that while scaling by registering and funding more relayers is possible (and will happen naturally as more ticket issuers are onboarding) going for this method of scaling off the bat is 'too easy'. TLDR: Relayers transmitting tx's are horizontally scaleable, but this has drawbacks operationally.
- A charataristic of the GETH nodes is that they can only hold in the mempool 16 tx per emitting account (so per relayer)
- As we use ERC721 and store considerable amount of metadata we can only mint 1 NFT per tx (350k gas, 1 tx = 1 mint)
- At any point in time a relayer can only offer 16tx's to the mempool

As we can only emit 16 tx at a time and every tx is 'only' 1 mint, hammering through transactions by raising gwei doesn't considerably speed up the amount we can process. Essentially with ERC721 we hit a processing limit that can only be relieved by using more relayers. Implementing EIP1155 will enable batch minting of 100+ getNFTs per tx. In addition using EIP1155 will reduce the need for more relayer for the same ticket issuer. 

#### Benefits of implementing EIP1155
- Huge cost savings (85-95% less Polygon needed per getNFT)
- Ability to batch mint 100 NFTs in a single transaction
- Ability to mint 1600 NFTs in 16 transactions

#### Downsides of implementing EIP1155
- Far less metadata permanently stored on chain of individual tickets
- Potential loss in (time) definition as NFTs are minted in batches (could disturb sequencing)
- Batch mints use a large abount of gas (2-3M) possibly Polygon nodes will be reluctant to take them when mempool is volatile (speculation, could not be the case)
- Increases complexity of ticket engine, as we will need to build a 'bucket' system
- Event logs could be pruned from the blockchain state

---

### BaseGET.sol

```jsx
primaryBatchSale(address eventAddress, uint256 startId, uint256 endId, uint256[] memory basePrices, uint256 orderTime)
```

The protocol now batch-mints tickets with the `primaryBatchSale` function, this function in turn emits `primaryBatchSaleMint` upon successful mints. This function takes in the `eventAddress` into which all the tickets in the this batch would be minted, A `startId` and `endId` which signifies the range of the token `ids` to be minted, an array of `basePrices` whose length must be in accordance to the amount of tickets being minted and the `orderTime`.

```jsx
event primaryBatchSaleMint(uint256 indexed startIndex, uint256 indexed endIndex, uint64 indexed getUsed, uint64 orderTime, uint256[] basePrices)
```

This event is emitted upon successfully batch minting tickets.

## Conclusion:

This is by far not conclusive neither is it sufficient enough a documentation to in detail state all the changes made. For clarity sake, I'd rewrite this once I have the contracts re-written and ready to be deployed on Mumbai.


## State Change Functions

### 1. `primarySale` Function - Responsible for single mints of NFTs

`eventAddress`  - Address of GET custody that would be unique per event. All tickets of a particular event would be minted into this address.

`id` - Unique id per token.

`primaryPrice` - Price paid by primary ticket buyer in the local/event currency

`basePrice` - price as charged by GET to the ticketeer in USD

`orderTime` -  timestamp the state change was triggered in the system of the integrator

`data` - any arbitrary data to be stored on-chain

`ticketMetadata` - additional meta data about a sale or ticket (like seating, notes, or resale rules) stored in a `struct`.

```jsx
function primarySale(address eventAddress, uint256 id, uint256 primaryPrice, uint256 basePrice, uint256 orderTime, bytes memory data, bytes32[] memory ticketMetadata) public onlyRelayer
```

emits `PrimarySaleMint` upon success
 

```jsx
PrimarySaleMint(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime, uint256 basePrice)
```

### 2. `primaryBatchSale` Function - Responsible for batch mints of NFTs

`eventAddress`  - Address of GET custody that would be unique per event. All tickets of a particular event would be minted into this address.

`ids` - Array of `ids`

`primaryPrices` - Array of `primaryPrices`.

`amounts` - Array of the number of a specific token to be minted. This number of elements in this array must correspond with the number of tokens to be minted. I.e `ids.length == amounts.length == basePrices.length`

`basePrices` - array of `basePrice`

`orderTime` -  timestamp the state change was triggered in the system of the integrator

`meta` - any arbitrary data to be stored on-chain

 

```jsx
function primaryBatchSale(address eventAddress,uint256[] memory ids,uint256[] memory amounts,uint256[] memory basePrices,uint256 orderTime,bytes memory meta) public onlyRelayer
```

This emits `PrimaryBatchMint` upon success

```jsx
PrimaryBatchMint(uint256[] indexed ids,uint64 indexed getUsed,uint64 orderTime,uint256[] indexed basePrices)
```

### 3. `secondaryTransfer` Function - Responsible for handling single ticket resales

`id` - NFT index

`eventAddress` - EOA address of GETCustody that is the event the getNFT was issued for

`orderTime` - timestamp the state change was triggered in the system of the integrator

`primaryPrice` -  price paid for the getNFT during the primary sale

`secondaryPrice` - price paid for the getNFT on the secondary market

```jsx
function secondaryTransfer(uint256 id,address eventAddress,uint256 orderTime,uint256 primaryPrice,uint256 secondaryPrice)
```

This emits `SecondarySale` upon success.

```jsx
SecondarySale(uint256 indexed nftIndex,uint64 indexed getUsed,uint256 resalePrice,uint64 indexed orderTime)
```

### 4.  `scanNFT` Function

 

`id` -  NFT index

`orderTime` -  timestamp of engine of request

`eventAddress` - EOA address of GETCustody that is the event the getNFT was issued for.

```jsx
function scanNFT(uint256 id,uint256 orderTime,address eventAddress) public onlyRelayer
```

This emits TicketScanned upon success.

```jsx
TicketScanned(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime);
```

### 5. `invalidateNFT` Function

`id` -  NFT index

`orderTime` -  timestamp of engine of request

`eventAddress` - EOA address of GETCustody that is the event the getNFT was issued for.

```jsx
function invalidateNFT(uint256 id,uint256 orderTime,address eventAddress) public onlyRelayer
```

This emits TicketInvalidated upon success.

```jsx
TicketInvalidated(uint256 indexed nftIndex,uint64 indexed getUsed,uint64 indexed orderTime)
```

### 6.  `claimGetNFT` Function

`id` - unique ticket ID

`eventAddress` - EOA address of GETCustody that is the known owner of the getNFT

`externalAddress` - EOA address of user that is claiming the getNFT

`orderTime` - timestamp the statechange was triggered in the system of the integrator

`data` - an arbitrary data to be stored on-chain

```jsx
function claimGetNFT(uint256 id,address eventAddress,address externalAddress,uint256 orderTime,bytes memory data)
```

This emits NftClaimed upon success

```jsx
NftClaimed(uint256 indexed nftIndex, uint64 indexed getUsed, uint64 indexed orderTime)
```

## View Functions

### 1.  `isNFTClaimable`  Function

`nftIndex` -   unique identifier of getNFT assigned by contract at mint

`eventAddress` -  EOA address of GETCustody that is the known owner of the getNFT

```jsx
isNFTClaimable(uint256 nftIndex, address eventAddress) public view returns (bool)
```

Returns a boolean.

### 2. `isNFTSellable` Function

`id` - unique identifier of getNFT assigned by contract at mint

```jsx
isNFTSellable(uint256 id) public view returns (bool)
```

Returns a boolean.

### 3. isNFTSellable Function

`nftIndex/id` - unique identifier of getNFT assigned by contract at mint

```jsx
returnStructTicket(uint256 nftIndex) public view returns (TicketData memory)
```

Returns a TicketData struct

```jsx
TicketData {
	address eventAddress; 
	bytes32[] ticketMetadata; 
	uint32[2] salePrices; 
	TicketStates state;
}
```

### 4. `viewPrimaryPrice` Function

`nftIndex/id` - unique identifier of getNFT assigned by contract at mint

```jsx
viewPrimaryPrice(uint256 nftIndex) public view returns (uint32)
```

Returns an integer

### 5. `viewLatestResalePrice` Function

`nftIndex/id` - unique identifier of getNFT assigned by contract at mint

```jsx
viewLatestResalePrice(uint256 nftIndex) public view returns (uint32)
```

Returns an integer

### 6. `viewEventOfIndex`  Function

`nftIndex/id` - unique identifier of getNFT assigned by contract at mint

```jsx
viewEventOfIndex(uint256 nftIndex) public view returns (address)
```

Returns an integer

### 7. `viewTicketMetadata` is an alias for `returnStructTicket`

### 8. `viewTicketState` Function

```jsx
viewTicketState(uint256 nftIndex) public view returns (uint256)
```

Returns an integer that represented a state within the state structure below

```jsx
TicketStates{
	UNSCANNED,
	SCANNED,
	CLAIMABLE,
	INVALIDATED,
	PREMINTED,
	COLLATERALIZED,
	CLAIMED
}
```

