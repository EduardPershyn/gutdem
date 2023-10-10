import { assert, expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";

import * as utils from "../scripts/deploy";

describe("DemNft Test", async () => {
  let demBacon: Contract;
  let growerDemNft: Contract;
  let toddlerDemNft: Contract;

  let accounts: Signer[];
  let account: string;
  let demBaconAddress: string;
  let growerDemNftAddress: string;
  let toddlerDemNftAddress: string;

  before(async () => {
    let deployOutput = await utils.main(false, true);
    demBaconAddress = deployOutput.demBacon;
    growerDemNftAddress = deployOutput.growerDemNft;
    toddlerDemNftAddress = deployOutput.toddlerDemNft;

    accounts = await ethers.getSigners();
    account = await accounts[0].getAddress();

    demBacon = await ethers.getContractAt(
      "DbnToken",
      demBaconAddress,
      accounts[0],
    );

    growerDemNft = await ethers.getContractAt(
      "SaleFacet",
      growerDemNftAddress,
      accounts[0],
    );

    toddlerDemNft = await ethers.getContractAt(
      "DemNft",
      toddlerDemNftAddress,
      accounts[0],
    );
  });

  it("Test", async () => {
    {
      let tx = await demBacon.setRewardManager(account);
      let receipt = await tx.wait();
      console.log(receipt.status);
      assert.equal(receipt.status, true, "game managers should be added");
    }
    {
      let tx = await growerDemNft.setRewardManager(account);
      let receipt = await tx.wait();
      console.log(receipt.status);
      assert.equal(receipt.status, true, "game managers should be added");
    }
  });
});
