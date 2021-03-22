const { ethers, upgrades } = require("hardhat");

const NUM_EVENTS = 5;
const NUM_TICKETS = 10;

async function main() {

  const accessCAddress = "0x085C06560d10b99C96DdA9B8503aE57D51863A3f";
  const metaCAddress = "0x3536C93F376e9c0F6cbE244005063B5888F8cb0B";
  const financeCAddress = "0xfcD93a9CF6cb05a64c8011fF1637Ee4e1b4D0b42"
  const baseCAddress = "0xaA699D95c42D6BdcC1D828d426b21A5eaDD9341e"
  const claimCAddress = "0xD75D4a98297273103B97557dC7fDeB333396EB84"

  const event_1 = "0x077A76A76c9c56f04c9aF90B5f6694697E2F3b40"
  const event_2 = "0x1A837C123D63b41bBE2BE4F83DEedFC29B81c713"
  const event_3 = "0x97c4e9711Fd7FF8D0e5D504345ed638D5E6a6E0C"
  const event_4 = "0x4044Ff75A345C5eb95760d5FC3F919ca28ED153f"
  const event_5 = "0x5A606E866B13AC872e4dEFdCDCD146c0AE964497"

  const list_events = [
    event_1, event_2, event_3, event_4, event_5
  ]

  const acc_1 = "0xBceba105BD5f008515eb1CcA3768CF4cd55CFfD3"
  const acc_2 = "0x27EeADB030c7d60b23Bb28D02D50Db662aFB92C3"
  const acc_3 = "0xf9d121128D940Ad6F47277373f8800C4bBFA929F"
  const acc_4 = "0xA5173cB1CfE7C7E154C96457db5D3B30b81aBC28"
  const acc_5 = "0x38c00CEb5ad0D8D0555D4734a9EC3422B90a44A7"
  const acc_6 = "0xC98Ff09bF4474f6649F864bFfe961c57a37D6740"
  const acc_7 = "0x63A9265a634351B304e55EAD9079AEB3fb3182Db"
  const acc_8 = "0x0C501479Df03701d441cf748daa27b7270651b07"
  const acc_9 = "0x388cE07d12d840e3e306553CfCa1809492dC6233"
  const acc_10 = "0x96F49c0E4e145bcA7b38589016725B28171a507c"

  const acc_11 = "0x077A76A76c9c56f04c9aF90B5f6694697E2F3b40"
  const acc_12 = "0x1A837C123D63b41bBE2BE4F83DEedFC29B81c713"
  const acc_13 = "0x97c4e9711Fd7FF8D0e5D504345ed638D5E6a6E0C"
  const acc_14 = "0x4044Ff75A345C5eb95760d5FC3F919ca28ED153f"
  const acc_15 = "0x5A606E866B13AC872e4dEFdCDCD146c0AE964497"
  const acc_16 = "0x8fACfFB0F12Ed81F595763F91dc91BFB1e9fa946"
  const acc_17 = "0x3f987235eEFDD65dF25eCA0925551dbc5C4E3b01"
  const acc_18 = "0xB87109e3eD895DFDcb8F1B43dF1B4d64a255A99b"
  const acc_19 = "0x95F1abcD1812696bD37B6194414038cE82b1c740"
  const acc_20 = "0x370918531D9Bbb14914dABa272f3a29eb9342c52"

  const list_accs = [
    acc_1, acc_2, acc_3, acc_4, acc_5, acc_6, acc_7, acc_8, acc_9, acc_10,
    acc_11, acc_12, acc_13, acc_14, acc_15, acc_16, acc_17, acc_18, acc_19, acc_20
  ]
  
  // const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE');
  // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE');
  // const acc_testing = "0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f";

  const Access = await ethers.getContractFactory("AccessControlGET");
  const access = Access.attach(accessCAddress);

  const metadataLogic = await ethers.getContractFactory("eventMetadataStorage");
  const meta = metadataLogic.attach(metaCAddress);

  const Base = await ethers.getContractFactory("baseGETNFT_V4");
  const base = Base.attach(baseCAddress);

  const Finance = await ethers.getContractFactory("getEventFinancing");
  const finance = Finance.attach(financeCAddress);

  const Claim = await ethers.getContractFactory("claimGETNFT");
  const claim = Claim.attach(claimCAddress);

  // const accounts = await ethers.getSigners();
  const main_acc = "0x6382Dcd7954Ef8d0D3C2A203aA1Bd3aE71c82e42";
  // const acc_2 = "0x6382Dcd7954Ef8d0D3C2A203aA1Bd3aE71c82e42";

  // Creatures issued directly to the owner.
  for (var i = 0; i < NUM_EVENTS; i++) {
    var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
    const result = await meta.registerEvent(
      list_events[i], // eventAddress
      main_acc, // integratorAccountPublicKeyHash
      claimCAddress, // underwriterAddress
      "Event name testing script 9", // eventName
      [bytedata, bytedata], // eventUrls
      [bytedata, bytedata, bytedata, bytedata], // eventMeta
      [111,i], // eventTimes
      true, // setAside
      [bytedata, bytedata] // extraData
      )
    console.log("Event metadata registered. Tx hash: " + result.hash + "   " + i);
    console.log("   ")
  }

  console.log("Event registration completed");

  // const accounts = await ethers.getSigners();

  for (var i = 0; i < NUM_TICKETS; i++) {
    var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    const result = await finance.mintSetAsideNFTTicket(
      claimCAddress, // underwriterAddress (destinationAddress)
      list_events[1], // eventAddress
      i + 1000, // orderTime
      i + 3000, // ticketDebt / price
      "Ticket URI testing 10", // ticketURI
      [bytedata]) // ticketMetadata
    // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
    // console.log("nftIndex of set aside NFT: " + nftindex)
    console.log("getNFT minted (to claimCAddress where it is colleterized). Transaction: " + result.hash + "   " + i)
    console.log("   ")
  }

  var balance_claim = await base.balanceOf(claimCAddress)
  console.log("Total balance of getNFTs on claim address: " + balance_claim)
  console.log("setAsideNFTTicket mint completed");
  console.log("   ")

  for (var i = 0; i < NUM_TICKETS; i++) {
    var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    var nftindex = await base.tokenOfOwnerByIndex(claimCAddress, 0);
    console.log("Colleterized token with nftIndex: " + nftindex + " sold in primary market.")
    console.log("This nft will be sold to address: " + list_accs[i])
    const result = await base.primarySale(
      list_accs[i], // destinationAddress
      list_events[0], // eventAddress
      i + 1000, // primaryPrice
      i + 3000, // orderTime
      "Ticket URI testing 10", // ticketURI
      [bytedata]) // ticketMetadata

    console.log("Transaction hash of primary market (from colleteralized inventory): " + result.hash + "   " + i)
    console.log("   ")
  }

  var balance_claim = await base.balanceOf(claimCAddress)
  console.log("Completed primary market - Total balance of getNFTs on claim address: " + balance_claim)
  console.log("   ")
  
  const start_ticket = NUM_TICKETS + 1
  const max_ticket = NUM_TICKETS * 2

  for (var i = start_ticket; i < max_ticket; i++) {
    // var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
    console.log("originAddress: " + list_accs[i-10])
    console.log("destinationAddress: " + list_accs[i])
    const result = await base.secondaryTransfer(
      list_accs[i-10], // originAddress
      list_accs[i], // destinationAddress
      i + 2000, // orderTime
      i + 9999 // secondaryPrice
      )
    // console.log()
    // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
    // console.log("nftIndex of transferred token: " + nftindex)
    console.log("Secondary transfer. Transaction: " + result.hash + "   " + i);
    console.log("   ")
  }

  console.log("secondaryTransfer completed");

  for (var i = start_ticket; i < max_ticket; i++) {
    // var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
    const result = await base.scanNFT(
      list_accs[i] // originAddress
      );
    console.log("Scanned. Transaction: " + result.hash + "   " + i);
  }

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});