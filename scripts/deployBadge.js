const { ethers } = require("hardhat");

module.exports = async () => {
  let wallet = (await ethers.getSigners())[0];

  const Badge = await ethers.getContractFactory("Badge", wallet);
  const badge = await Badge.deploy();
  const badgeAddress = (await badge.deployTransaction.wait()).contractAddress;
  console.log(`Badge deployed to: ${badgeAddress}`);

  return badgeAddress;
};
