import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      chainId: 1337,
    },
  },
  solidity: "0.8.29",
};

export default config;
