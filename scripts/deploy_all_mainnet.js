const { ethers, upgrades } = require("hardhat");

const NUM_CREATURES1 = 5;
const NUM_CREATURES2 = 10;

async function main() {
    // We get the contract to deploy
    const AccessControlGET = await ethers.getContractFactory("AccessControlUpgradeableGET");
    console.log("Deploying AccessControlGET...");
    const _access = await upgrades.deployProxy(AccessControlGET, { initializer: '__AccessControlGET_init' });
    await _access.deployed();
    console.log("Access Control upgradeable deployed to:", _access.address);

    const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE');
    const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE');
    const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');
    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

    // const accounts = await ethers.getSigners();

    // minter0 = await _access.getRoleMemberCount(MINTER_ROLE);
    // console.log("Amount of MINTER roles is: ", minter0.toString());

    // admin0 = await _access.hasRole(DEFAULT_ADMIN_ROLE, accounts[1].address);
    // console.log("Account 0 is the admin (true): ", admin0.toString());

    // factory0 = await _access.getRoleMemberCount(FACTORY_ROLE);
    // console.log("Amount of Factory roles is: ", factory0.toString());

    // admin1 = await _access.hasRole(MINTER_ROLE, accounts[1].address);
    // console.log("Account 1 is the minter (false): ", admin1.toString());

    // const result = await _access.connect(accounts[0]).grantRole(MINTER_ROLE, accounts[1].address);

    // admin2 = await _access.hasRole(MINTER_ROLE, accounts[1].address);
    // console.log("Account 1 is the minter (true): ", admin2.toString());

    const testGET = await ethers.getContractFactory("bscGETtest");
    console.log("Deploying getBSC test ERC20...");
    const _testget = await testGET.deploy();
    await _testget.deployed();
    console.log("Test BSC deployed to:", _testget.address);

    // Normal metadata contract with proxy
    const metadataLogic = await ethers.getContractFactory("metadataLogic");
    console.log("Deploying metadataLogic Proxy...");
    const _metadata = await upgrades.deployProxy(metadataLogic, [_access.address], { initializer: '__initialize_metadata' });
    await _metadata.deployed();
    console.log("Metadata deployed to:", _metadata.address);


  // Normal metadata contract
    const Base = await ethers.getContractFactory("baseNFT");
    console.log("Deploying baseNFT...");
    const base = await upgrades.deployProxy(Base, [_access.address, _metadata.address], { initializer: 'initialize_base' });
    await base.deployed();
    console.log("BaseNFT deployed to:", base.address);

    var _bal = await _testget.balanceOf(base.address);
    console.log("1 Balance of base proxy contract: " + _bal);

    // Providing testGET to the base and/or proxy contract
    const _ercmint = await _testget.mint(base.address, 10000000000023);

    var _bal2 = await _testget.balanceOf(base.address);
    console.log("2 Balance of base proxy contract: " + _bal2);

    // const accounts = await ethers.getSigners();
    const main_acc = "0xC58B20C01c1f24E72EE2c36A773EF48E774EA595";
    const acc_2 = "0xC58B20C01c1f24E72EE2c36A773EF48E774EA595";

    const result = await _access.grantRole(FACTORY_ROLE, base.address);
    // const result = await _access.connect(accounts[0]).grantRole(FACTORY_ROLE, base.address);

    var amount_nfts = await base.totalSupply();
    console.log("Total amount_nfts of events:" + amount_nfts); 

    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_CREATURES1; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
      const result = await base.primaryMint(acc_2, main_acc,  321, bytedata);
      console.log("Minted. Transaction: " + result.hash + "   " + i);
    }

    var amount_nfts = await base.totalSupply();
    console.log("Total amount_nfts of events dadf:" + amount_nfts); 

    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_CREATURES2; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
      const result = await base.registerEvent(acc_2, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata, bytedata);
      console.log("Event metadata registered. Transaction: " + result.hash + "   " + i);
    }

    var _bal3 = await _testget.balanceOf(base.address);
    console.log("3 Balance of base proxy contract: " + _bal3);
    // var amount_events = await base.getEventCount();
    // console.log("Total amount of events:" + amount_events);

    // // Creatures issued directly to the owner.
    // for (var i = 0; i < NUM_CREATURES1; i++) {
    //   const called = await base.getEventDataAll(accounts[i].address);
    //   console.log("Event metadata: " + i + called);
    // }

    // const result = await _access.connect(accounts[0]).grantRole(FACTORY_ROLE, accounts[1].address);
    
    // factory0 = await _access.getRoleMemberCount(FACTORY_ROLE);
    // console.log("Amount of Factory roles is: ", factory0.toString());

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });



