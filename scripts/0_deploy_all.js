const { ethers, upgrades } = require("hardhat");

const NUM_EVENTS = 5;
const NUM_TICKETS = 10;

async function main() {

    console.log("Start of deploying all contracts.")


    // Deploying access control 
    const Access = await ethers.getContractFactory("AccessControlGET");
    console.log("1 Deploying AccessControlGET...");
    const access = await upgrades.deployProxy(Access, { initializer: '__AccessControlGET_init' });
    await access.deployed();
    console.log("Access Control upgradeable deployed to:", access.address);


  // We need this special Proxy helper class,
  // because Proxy smart contract is very special and we can't
  // e.g. refer to Proxy.admin() directly
  // proxy = new Proxy(proxyContract.address);

    // const Proxy = await ethers.getContractFactory("AdminUpgradeabilityProxy")
    // const proxy = await ethers.getContractAt(access.address)
    // proxy = new Proxy(access);
    // const access_impl = await proxy.implementation()
    // console.log("Access Control implementation deployed to:", access_impl);

    const accessCAddress = access.address

    // Deploy the ERC721 Upgradable token
    const ERC721 = await ethers.getContractFactory("getNFT_ERC721");
    console.log("2 Deploying ERC721 Upgradable Proxy...");
    const erc721 = await upgrades.deployProxy(ERC721, [accessCAddress], { initializer: 'initialize_erc721' });
    await erc721.deployed();
    console.log("ERC721 deployed to:", erc721.address);

    const ERC721CAddress = erc721.address

    
    // Normal metadata contract with proxy
    const Metadata = await ethers.getContractFactory("eventMetadataStorage");
    console.log("2 Deploying metadataLogic Proxy...");
    const metadata = await upgrades.deployProxy(Metadata, [accessCAddress], { initializer: '__initialize_metadata' });
    await metadata.deployed();
    console.log("Metadata deployed to:", metadata.address);

    const metaCAddress = metadata.address;

    const Finance = await ethers.getContractFactory("getEventFinancing");
    console.log("3 Deploying financing Proxy...");
    const finance = await upgrades.deployProxy(Finance, [accessCAddress], { initializer: 'initialize_event_financing' });
    await finance.deployed();
    console.log("Finance deployed to:", finance.address);

    const financeCAddress = finance.address


    const Base = await ethers.getContractFactory("baseGETNFT_V4");
    console.log("Deploying baseNFT...");
    const base = await upgrades.deployProxy(Base, [accessCAddress, metaCAddress, financeCAddress, ERC721CAddress], { initializer: 'initialize_base' });
    await base.deployed();
    console.log("BaseNFT deployed to:", base.address);

    const baseCAddress = base.address

    // // Normal metadata contract
    // const Claim = await ethers.getContractFactory("claimGETNFT");
    // console.log("Deploying claimGETNFT...");
    // const claim = await upgrades.deployProxy(Claim, [accessCAddress, baseCAddress], { initializer: 'initialize_claim_nft' });
    // await claim.deployed();
    // console.log("claimGETNFT deployed to:", claim.address);

    // const claimCAddress = claim.address

    console.log("Accessmanager proxy deployed at:" + accessCAddress)
    console.log("Metadata proxy deployed at:" + metaCAddress)
    console.log("Finance proxy deployed at:" + financeCAddress)
    console.log("getNFT Base proxy deployed at:" + baseCAddress)
    // console.log("Claim prox deployed at:" + claimCAddress)
    console.log("ERC721 proxy deployed to:", ERC721CAddress)

    const RELAYER_ROLE = web3.utils.soliditySha3('RELAYER_ROLE')
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE')

    console.log("Start with initalizing the access control contract with the proxy contract addresses.")

    const acc_testing = "0x6058233f589DBE86f38BC64E1a77Cf16cf3c6c7e"

    // const Access = await ethers.getContractFactory("AccessControlGET")
    // const access = Access.attach(accessCAddress)

    console.log("Granting minting access to:", financeCAddress)
    await access.grantRole(RELAYER_ROLE, financeCAddress)
    console.log("Completed 1/4")

    console.log("Granting minting access to:", baseCAddress)
    await access.grantRole(RELAYER_ROLE, baseCAddress)
    console.log("Completed 2/4")

    // console.log("Granting minting access to:", acc_testing)
    // await access.grantRole(RELAYER_ROLE, acc_testing)
    // console.log("Completed 3/4")


    // console.log("Granting minting access to:", baseCAddress)
    // const result6 = await access.grantRole(FACTORY_ROLE, baseCAddress)
    // console.log("Done")

    console.log("Initalizing the (proxy) address of baseNFT in the finance contract ", financeCAddress)
    var result = await finance.configureBase(baseCAddress);
    console.log("Done")

    const accounts = await ethers.getSigners();
    console.log("Granting minting access to:", accounts[0].address)
    var result = await access.connect(accounts[0]).grantRole(RELAYER_ROLE, accounts[0].address);

    console.log("  ")
    console.log("Accessmanager proxy deployed at: " + accessCAddress)
    console.log("Metadata proxy deployed at: " + metaCAddress)
    console.log("Finance proxy deployed at: " + financeCAddress)
    console.log("Base proxy deployed at: " + baseCAddress)
    // console.log("Claim proxy deployed at: " + claimCAddress)

    // const accessCAddress = "0xe549607dB66cfc90073f815FA3343d2a3a001D8c";
    // const metaCAddress = "0x5Ef355b61f71D5D51F40f7de47752Cfe1D7F9A8f";
    // const financeCAddress = "0x67D2A56D331C5Ee462bC883c36E5dE453fc55E30"
    // const baseCAddress = "0x369E54e9c70893Dd1a8000E8880BB9c75B822655"
    // const claimCAddress = "0xb32D5B42AfC0F3B5ceD678Ed193Bc3A2DA1d93E0"
  
    const event_1 = "0x077A76A76c9c56f04c9aF90B5f6694697E2F3b40"
    const event_2 = "0x1A837C123D63b41bBE2BE4F83DEedFC29B81c713"
    const event_3 = "0x97c4e9711Fd7FF8D0e5D504345ed638D5E6a6E0C"
    const event_4 = "0x4044Ff75A345C5eb95760d5FC3F919ca28ED153f"
    const event_5 = "0x5A606E866B13AC872e4dEFdCDCD146c0AE964497"
  
    const list_events = [
      event_1, event_2, event_3, event_4, event_5
    ]
  
    const acc_1 = "0xBceba105BD5f008515eb1CcA3768CF4cd55CFfD3"
    const acc_2 = "0xAE8A19adE137A412CEc229Ba667331546349be38"
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

    const acc_21 = "0x370449aa4A559582924292A60931BFb24E32067B"
    const acc_22 = "0xe7B279EbA5937d958cE1bd0a618E0167a8159906"
    const acc_23 = "0xF48a25A44be2A67C62ee6342E606E4eC0eDBD60c"
    const acc_24 = "0x76e49F0bA4534cD6D618b7F0270fB0956AC55Eac"
    const acc_25 = "0x888725576DA8e6E9F0F19FAf92903161953d96D6"

    const acc_26 = "0x6f90d934ffe4895811d1a8C81f6f48edB33FA7b5"
    const acc_27 = "0xfF5Ac34d29E9De0043E99823b336500806D3bE6b"
    const acc_28 = "0x0C9fc7D2D873bc1F445D64d0bCEB4B0712f3B2D2"
    const acc_29 = "0x91c66251e86562fE0f595F6375f9457B6bec81ef"
    const acc_30 = "0xA2cCee6db20D7559Bd47529DF78D496569d034d6"
  
    const list_accs = [
      acc_1, acc_2, acc_3, acc_4, acc_5, acc_6, acc_7, acc_8, acc_9, acc_10,
      acc_11, acc_12, acc_13, acc_14, acc_15, acc_16, acc_17, acc_18, acc_19, acc_20,
      acc_21, acc_22, acc_23, acc_24, acc_25, acc_26, acc_27, acc_28, acc_29, acc_30
    ]
    
    // const RELAYER_ROLE = web3.utils.soliditySha3('RELAYER_ROLE');
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE');
    // const acc_testing = "0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f";
  
    // const Access = await ethers.getContractFactory("AccessControlGET");
    // const access = Access.attach(accessCAddress);
  
    // const metadataLogic = await ethers.getContractFactory("eventMetadataStorage");
    // const meta = metadataLogic.attach(metaCAddress);
  
    // const Base = await ethers.getContractFactory("baseGETNFT_V4");
    // const base = Base.attach(baseCAddress);
  
    // const Finance = await ethers.getContractFactory("getEventFinancing");
    // const finance = Finance.attach(financeCAddress);
  
    // const Claim = await ethers.getContractFactory("claimGETNFT");
    // const claim = Claim.attach(claimCAddress);
  
    // const accounts = await ethers.getSigners();
    const main_acc = "0x6382Dcd7954Ef8d0D3C2A203aA1Bd3aE71c82e42";
    // const acc_2 = "0x6382Dcd7954Ef8d0D3C2A203aA1Bd3aE71c82e42";
  
    const event_name = "Awesome Event Name"
    const shop_url = "ticketeer.io/event/shop"
    const image_url = "ticketeer.io/shop/image.jpg"
    const latitude_test = "-12.2345673"
    const longitude_test = "123.9876543"
    const currency_test = "EUR"
    const ticketeer_name_t = "Awesome Ticketeer"
    const start_time_test = 1616584929
    const stop_top_test = 1616589089
    const set_aside_test = false // bool 
    const extra_data_test = "awesome_ticketeer_id"
  
  
    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_EVENTS; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      const result = await metadata.registerEvent(
        list_events[i], // eventAddress
        main_acc, // integratorAccountPublicKeyHash
        // claimCAddress, // underwriterAddress
        event_name, // eventName
        // [ethers.utils.formatBytes32String(shop_url), ethers.utils.formatBytes32String(image_url)], // eventUrls
        shop_url,
        image_url,
        [ethers.utils.formatBytes32String(latitude_test), ethers.utils.formatBytes32String(longitude_test), ethers.utils.formatBytes32String(currency_test), ethers.utils.formatBytes32String(ticketeer_name_t)], // eventMeta
        [start_time_test,stop_top_test], // eventTimes
        set_aside_test, // setAside
        [ethers.utils.formatBytes32String(extra_data_test)] // extraData
        )
      console.log("Event registered:" + list_events[i]);
      console.log("Tx hash: " + result.hash + " count:  " + i);
      console.log("   ")
    }
  
    console.log("Event registration completed");
    console.log("   ")
  
    // const accounts = await ethers.getSigners();
  
    for (var i = 0; i < NUM_TICKETS; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      const result = await base.primarySale(
        list_accs[i], // destinationAddress
        list_events[0], // eventAddress
        i + 1000, // primaryPrice
        i + 3000, // orderTime
        "Ticket URI testing 9", // ticketURI
        [bytedata]) // ticketMetadata
      // var x = await contractInstance.methods.getIdentifier().call();
    //   console.log("Mint done")
      // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
      // console.log("nftIndex of minted token: " + nftindex)
      console.log("NFT minted. Recipient: " + list_accs[i])
      console.log("Tx hash: " + result.hash + "   " + i)
      console.log("   ")
    }
  
    console.log("Primary minting completed");
    console.log("   ")
  
    const start_ticket = 10
    const max_ticket = 20
  
    for (var i = start_ticket; i < max_ticket; i++) {
      // var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
      console.log("NFT from: " + list_accs[i-10] + " sent to: " + list_accs[i])
      const result = await base.secondaryTransfer(
        list_accs[i-10], // originAddress
        list_accs[i], // destinationAddress
        i + 2000, // orderTime
        i + 9999 // secondaryPrice
        )
    //   console.log("Secondary done")
      // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
      // console.log("nftIndex of minted token: " + nftindex)
    //   console.log("NFT from: " + list_accs[i-10] + "sent to: " + list_accs[i])
      console.log("Tx hash: " + result.hash + "   " + i);
      console.log("   ")
    }
  
    console.log("secondaryTransfer completed");
    console.log("   ")

    console.log("Start of ticket scanning process");
    console.log("   ")    

    for (var i = start_ticket; i < max_ticket; i++) {
      const result = await base.scanNFT(
        list_accs[i] // originAddress
        );
      // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
      // console.log("nftIndex of scanned token: " + nftindex)
      console.log("Scanned. TxHash: " + result.hash);
      console.log("   ")
    }

    console.log("Start of NFT claiming process");
    console.log("   ")

    const start_claim = 20
    const claim_max = 30

    for (var i = start_claim; i < claim_max; i++) {
      console.log("NFT from: " + list_accs[i-10] + " sent to claimAddress: " + list_accs[i])
      const result = await base.claimgetNFT(
        list_accs[i-10], // originAddress
        list_accs[i] // claimAddress
        )
    //   console.log("Secondary done")
      // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
      // console.log("nftIndex of minted token: " + nftindex)
    //   console.log("NFT from: " + list_accs[i-10] + "sent to: " + list_accs[i])
      console.log("Tx hash: " + result.hash + "   " + i);
      console.log("   ")
    }

    console.log("End of NFT claiming process");
    console.log("   ")

    console.log("Start of NFT claiming process");
    console.log("   ")

    const result_col = await metadata.registerEvent(
        list_events[2], // eventAddress
        main_acc, // integratorAccountPublicKeyHash
        // claimCAddress, // underwriterAddress
        "COLLETERIZED EVENT TESTING", // eventName
        // [ethers.utils.formatBytes32String(shop_url), ethers.utils.formatBytes32String(image_url)], // eventUrls
        shop_url,
        image_url,
        [ethers.utils.formatBytes32String(latitude_test), ethers.utils.formatBytes32String(longitude_test), ethers.utils.formatBytes32String(currency_test), ethers.utils.formatBytes32String(ticketeer_name_t)], // eventMeta
        [start_time_test,stop_top_test], // eventTimes
        true, // setAside
        [ethers.utils.formatBytes32String(extra_data_test)] // extraData
        )
    console.log("Colleteraized Event registered:" + list_events[2]);
    console.log("Tx hash: " + result_col.hash);
    console.log("   ")

    // for (var i = 0; i < NUM_TICKETS; i++) {
    //     var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
    //     const result = await finance.mintSetAsideNFTTicket(
    //       claimCAddress, // underwriterAddress (destinationAddress)
    //       list_events[1], // eventAddress
    //       i + 1000, // orderTime
    //       i + 3000, // ticketDebt / price
    //       "Ticket URI testing 10", // ticketURI
    //       [bytedata]) // ticketMetadata
    //     // var nftindex = await base.tokenOfOwnerByIndex(list_accs[i], 0);
    //     // console.log("nftIndex of set aside NFT: " + nftindex)
    //     console.log("getNFT minted (to claimCAddress where it is colleterized). Transaction: " + result.hash + "   " + i)
    //     console.log("   ")
    //   }

      console.log("Accessmanager proxy deployed at: " + accessCAddress)
      console.log("Metadata proxy deployed at: " + metaCAddress)
      console.log("Finance proxy deployed at: " + financeCAddress)
      console.log("getNFT Base proxy deployed at: " + baseCAddress)
      // console.log("Claim prox deployed at: " + claimCAddress)      
      console.log("ERC721 proxy deployed to: ", ERC721CAddress)
      
      // console.log("Access Control implementation deployed to:", access_impl);

}
    
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});