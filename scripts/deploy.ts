import { ethers } from "hardhat";
import { deployConfig as cfg } from "../deploy.config";

async function main() {
  let accounts = await ethers.getSigners();
  let account = await accounts[0].getAddress();

  async function demBaconDeploy(): Promise<string> {
    const lock = await ethers.deployContract("DbnToken", [
      [account, cfg.dbnName, cfg.dbnSymbol],
    ]);

    return lock.target;
  }

  //   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  //   const unlockTime = currentTimestampInSeconds + 60;
  //
  //   const lockedAmount = ethers.parseEther("0.001");
  //
  //   const lock = await ethers.deployContract("Lock", [unlockTime], {
  //     value: lockedAmount,
  //   });
  //
  //   await lock.waitForDeployment();
  //
  //   console.log(
  //     `Lock with ${ethers.formatEther(
  //       lockedAmount
  //     )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  //   );

  const dbnAddress = await demBaconDeploy();
  console.log(dbnAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
