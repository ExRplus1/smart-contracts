require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

task("show-balance", async () => {
  const showBalance = require("./scripts/showBalance");
  return showBalance();
});

task("deploy-badge", async () => {
  const deployContract = require("./scripts/deployBadge");
  return deployContract();
});

task("deploy-surveys", async () => {
  const deployContract = require("./scripts/deploySurveys");
  return deployContract();
});

task("contract-view-call", async (taskArgs) => {
  const contractViewCall = require("./scripts/contractViewCall");
  return contractViewCall(taskArgs.contractAddress);
});

// task("contract-call", async (taskArgs) => {
//   const contractCall = require("./scripts/contractCall");
//   return contractCall(taskArgs.contractAddress, taskArgs.msg);
// });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  mocha: {
    timeout: 3600000,
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  defaultNetwork: "localnet",
  networks: {
    testnet: {
      url: process.env.TESTNET_ENDPOINT,
      accounts: [
        process.env.TESTNET_OPERATOR_PRIVATE_KEY,
      ],
    },
    localnet: {
      url: process.env.LOCALNET_ENDPOINT,
      accounts: [
        process.env.LOCALNET_OPERATOR_PRIVATE_KEY,
      ],
    },
  },
};
