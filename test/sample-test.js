const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT", function() {
  it("It should deploy the contract, mint a token, and resolve to the right URI", async function() {
    [owner] = await ethers.getSigners();
    console.log("deployer address: ", owner.address);
    const NFT = await ethers.getContractFactory("BadNFT");
    const nft = await NFT.deploy();
    console.log("contract address: ", nft.address);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    await nft.deployed();
    await nft.mint("0xE99EaDA4Da93533A29F059C7aE8c2a8112Cf412C", URI);
    expect(await nft.tokenURI(1)).to.equal(URI);
  });
});
