// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CustomNFT = await ethers.getContractFactory("CustomNFT");
  const customNFT = await CustomNFT.deploy();

  console.log("CustomNFT address:", customNFT.address);

  // Pay fee and add deployer as an approved user
  const fee = ethers.utils.parseUnits("0.1", "ether");
  const feeRecipient = "0x1234567890123456789012345678901234567890"; // replace with actual fee recipient address

  console.log(
    `Transferring ${ethers.utils.formatEther(fee)} MATIC to ${feeRecipient}...`
  );
  const tx1 = await deployer.sendTransaction({
    to: feeRecipient,
    value: fee,
  });
  await tx1.wait();

  console.log(`Adding ${deployer.address} as an approved user...`);
  const tx2 = await customNFT.addApprovedUser(deployer.address);
  await tx2.wait();

  console.log(
    `Deployer ${deployer.address} is now an approved user and can mint NFTs!`
  );

  // Create NFTs
  const customNFT2 = await ethers.getContractAt("CustomNFT", customNFT.address);

  console.log("Creating NFT #1...");
  const tx3 = await customNFT2.createNFT("https://mybaseurl.com/1");
  await tx3.wait();
  console.log("Created NFT #1");

  console.log("Creating NFT #2...");
  const tx4 = await customNFT2.createNFT("https://mybaseurl.com/2");
  await tx4.wait();
  console.log("Created NFT #2");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
