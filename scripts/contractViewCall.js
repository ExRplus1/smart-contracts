const { ethers } = require("hardhat");

module.exports = async (address) => {
  const wallet = (await ethers.getSigners())[0];
  const surveys = await hre.ethers.getContractAt("Surveys", address, wallet);
  const callRes = await surveys.getSurveys();

  console.log(`Surveys call result: ${callRes}`);

  return callRes;
};
