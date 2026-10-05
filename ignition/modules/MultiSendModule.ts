import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MultiSendModule", (m) => {
  const multiSend = m.contract("MultiSend");

  return { multiSend };
});