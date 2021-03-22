const { ethers, upgrades } = require("hardhat");

async function main() {

    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";
    const metaCAddress = "0x61bf7D94ed434cF50c36342DD7f5b83B803839f9";
    const financeCAddress = "0xF1dC80ae74eA126B17387C8010fA31C2969eC7F2"

    const baseCAddress = "0xfCbC4b1a1faca60e00B3cbaCd5AD8ce998518051"
    const claimCAddress = "0x02192Ada9cC91b06559f697947a7606938cc8989"

    const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE')
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE')

    const acc_testing = "0x6058233f589DBE86f38BC64E1a77Cf16cf3c6c7e"

    const Access = await ethers.getContractFactory("AccessControlGET")
    const access = Access.attach(accessCAddress)

    console.log("Granting minting access to:", financeCAddress)
    const result1 = await access.grantRole(MINTER_ROLE, financeCAddress)
    console.log("Completed 1/4")

    console.log("Granting minting access to:", baseCAddress)
    const result2 = await access.grantRole(MINTER_ROLE, baseCAddress)
    console.log("Completed 2/4")

    console.log("Granting minting access to:", acc_testing)
    const result3 = await access.grantRole(MINTER_ROLE, acc_testing)
    console.log("Completed 3/4")

    console.log("Granting minting access to:", claimCAddress)
    const result4 = await access.grantRole(MINTER_ROLE, claimCAddress)
    console.log("Completed 4/4")

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