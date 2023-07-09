const hre = require("hardhat")
const ethers = hre.ethers

async function main(){
    const [signer] = await ethers.getSigners()

    const Erc = await ethers.getContractFactory("MerandShop", signer)
    const erc = await Erc.deploy()
    await erc.deployed()
    console.log(erc.address)
    console.log(await erc.token())
}
// в терминал -> npx hardhat run scripts\deploy-ERC20.js
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });