const { ethers } = require("hardhat");

module.exports = async () => {
  let wallet = (await ethers.getSigners())[0];
  
  const Surveys = await ethers.getContractFactory("Surveys", wallet);
  const surveys = await Surveys.deploy();
  const surveysAddress = (await surveys.deployTransaction.wait())
    .contractAddress;
  console.log(`Surveys deployed to: ${surveysAddress}`);

  return surveysAddress;
};
