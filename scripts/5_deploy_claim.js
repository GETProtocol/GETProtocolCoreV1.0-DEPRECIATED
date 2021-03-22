const { ethers, upgrades } = require("hardhat");

async function main() {
    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";
    const baseCAddress = "0xfCbC4b1a1faca60e00B3cbaCd5AD8ce998518051"
    // const metaCAddress = "0x684c386aea32898fdB569620e5BC9c9C05d4bb24";
    // const financeCAddress = "0x9B16836f9f8aB3147dFAc1cbdA8D4F948148776e"

    // Normal metadata contract
    const Claim = await ethers.getContractFactory("claimGETNFT");
    console.log("Deploying claimGETNFT...");
    const claim = await upgrades.deployProxy(Claim, [accessCAddress, baseCAddress], { initializer: 'initialize_claim_nft' });
    await claim.deployed();
    console.log("claimGETNFT deployed to:", claim.address);

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});