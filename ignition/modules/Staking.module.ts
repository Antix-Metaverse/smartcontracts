import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingContractModule = buildModule("StakingContractModule", (m) => {
  const staking = m.contract("Staking", [
    m.getParameter("stakingtoken"),
    m.getParameter("accessnft"),
    m.getParameter("weeklypool"),
  ]);
  return { staking };
});

export default StakingContractModule;

//example
// npx hardhat ignition deploy ignition/modules/Staking.module.ts \
//   --parameters '{"StakingContractModule": {"stakingtoken":"0x1111111111111111111111111111111111111111","accessnft":"0x1111111111111111111111111111111111111111","weeklypool":"1000000000000000000000"}}'
