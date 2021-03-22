const { ethers, upgrades } = require("hardhat");

async function main() {

    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";
    // const metaCAddress = "0xdc847Ce9c1219C3246D874d1C2BB1669E2A25837";
    const financeCAddress = "0xF1dC80ae74eA126B17387C8010fA31C2969eC7F2"
    const baseCAddress = "0xfCbC4b1a1faca60e00B3cbaCd5AD8ce998518051"

    const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE')
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE')

    // const acc_testing = "0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f"

    const Access = await ethers.getContractFactory("AccessControlGET")
    const access = Access.attach(accessCAddress)

    // console.log("Granting minting access to:", acc_testing)
    // const result3 = await access.grantRole(MINTER_ROLE, acc_testing)
    // console.log("Done")

    const accounts = await ethers.getSigners();
    console.log("Granting minting access to:", accounts[0].address)
    const result = await access.connect(accounts[0]).grantRole(MINTER_ROLE, accounts[0].address);

    // console.log("Granting minting access to:", baseCAddress)
    // const result6 = await access.grantRole(FACTORY_ROLE, baseCAddress)
    console.log("Completed 1/1")

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});