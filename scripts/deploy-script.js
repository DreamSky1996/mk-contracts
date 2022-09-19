const hre = require("hardhat");

async function main() {
  const name = "MergeKingdom";
  const symbol = "MK";
  const base_uri = "";
  const not_revealed_url = "";
  const mint_cost = "1000000000";
  const mint_per_tx = "10";

  const Silver = await hre.ethers.getContractFactory("Silver");
  const silver = await Silver.deploy();
  await silver.deployed();
  console.log("Silver deployed to:", silver.address);
  const MKNFT = await hre.ethers.getContractFactory("MergeKingdom");
  const mkNFT = await MKNFT.deploy(name, symbol, base_uri, not_revealed_url, silver.address, mint_cost, mint_per_tx);
  await mkNFT.deployed();
  console.log("MergeKingdom deployed to:", mkNFT.address);
}main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
