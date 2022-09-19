const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("BadNFT");
  const URI = "ipfs://QmbJQgaHCP7J8c7hyUQifRGoYg7HJ86UcNg8JjHhbAQdJ3";
  const WALLET_ADDRESS = "0xE99EaDA4Da93533A29F059C7aE8c2a8112Cf412C";
  const CONTRACT_ADDRESS = "0xBE8978Da07eE42D19C226feEfB7A11e8EfC40100";

  const contract = NFT.attach(CONTRACT_ADDRESS);
  await contract.mint(WALLET_ADDRESS, URI);
  console.log("NFT minted:", contract);
}main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
