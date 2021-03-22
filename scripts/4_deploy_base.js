const { ethers, upgrades } = require("hardhat");

async function main() {

    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";
    const metaCAddress = "0x61bf7D94ed434cF50c36342DD7f5b83B803839f9";
    const financeCAddress = "0xFCc7F640E649B4fCADed9b45cA8F3908962C4677"

    // Normal metadata contract
    const Base = await ethers.getContractFactory("baseGETNFT_V4");
    console.log("Deploying baseNFT...");
    const base = await upgrades.deployProxy(Base, [accessCAddress, metaCAddress, financeCAddress], { initializer: 'initialize_base' });
    await base.deployed();
    console.log("BaseNFT deployed to:", base.address);

}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});