const { ethers } = require("hardhat");

module.exports = async (address, msg) => {
  const wallet = (await ethers.getSigners())[0];

  const survey = await ethers.getContractAt("Survey", address, wallet);

  const updateTx = await survey.setSurvey(msg);

  console.log(`Updated call result: ${msg}`);

  return updateTx;
};
