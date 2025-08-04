import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("VotingToken", (m) => {
  const token = m.contract("VotingToken", []);

  return { token };
});
