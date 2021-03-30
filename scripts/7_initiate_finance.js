const { ethers, upgrades } = require("hardhat");

async function main() {

    // const accessCAddress = "0x77803Cf891fb37beb5cd05b8F59043d323979A50";
    // const metaCAddress = "0x97dFEc427756a23136A08812a3c1BB12cd0d074b";
    const baseCAddress = "0xfCbC4b1a1faca60e00B3cbaCd5AD8ce998518051"
    const financeCAddress = "0xF1dC80ae74eA126B17387C8010fA31C2969eC7F2";

    // const RELAYER_ROLE = web3.utils.soliditySha3('RELAYER_ROLE')
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE')

    // const acc_testing = "0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f"

    const Finance = await ethers.getContractFactory("getEventFinancing")
    const finance = Finance.attach(financeCAddress)

    console.log("Initalizing the (proxy) address of baseNFT in the finance contract ", financeCAddress)
    const result = await finance.configureBase(baseCAddress);
    console.log("Done")

    // console.log("Granting minting access to:", baseCAddress)
    // const result6 = await access.grantRole(FACTORY_ROLE, baseCAddress)
    // console.log("Done")

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});