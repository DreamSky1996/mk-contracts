const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("BadNFT");
  const CONTRACT_ADDRESS = "0xBE8978Da07eE42D19C226feEfB7A11e8EfC40100";

  const contract = NFT.attach(CONTRACT_ADDRESS);

  const owner = await contract.ownerOf(1);
  console.log("Owner:", owner);
  const uri = await contract.tokenURI(1);
  console.log("URI: ", uri);
}main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
