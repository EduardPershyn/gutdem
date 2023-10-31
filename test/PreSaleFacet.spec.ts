import { assert, expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { helpers } from "./shared/helpers";
import { deployConfig as testCfg } from "../deploy-test.config";

import * as utils from "../scripts/deploy";

describe("DemRebel PreSaleFacet Test", async () => {
  let preSaleFacet: Contract;
  let demRebel: Contract;

  let accounts: Signer[];

  let demRebelAddress: string;

  before(async () => {
    const deployOutput = await utils.main(true, true);
    demRebelAddress = deployOutput.demRebel;

    accounts = await ethers.getSigners();

    preSaleFacet = await ethers.getContractAt(
      "PreSaleFacet",
      demRebelAddress,
      accounts[0],
    );
    demRebel = await ethers.getContractAt(
      "DemRebel",
      demRebelAddress,
      accounts[0],
    );
  });

  it("Check mint limits", async () => {
    const account = accounts[1];

    await preSaleFacet.setMaxDemRebelsSalePerUser(testCfg.maxDemRebels);

    for (let i = 0; i < 9; i++) {
      await helpers.purchaseRebels(preSaleFacet, account, 100);
    }
    {
      const count = 100 + 1;
      const tx = preSaleFacet.connect(account).purchaseDemRebels(count, {
        value: testCfg.demRebelSalePrice * BigInt(count),
      });
      await expect(tx).to.be.revertedWith(
        "SaleFacet: First part mint reached max cap",
      );
    }
    await helpers.purchaseRebels(preSaleFacet, account, 100);

    {
      const count = 1;
      const tx = preSaleFacet.connect(account).purchaseDemRebels(count, {
        value: testCfg.demRebelSalePrice * BigInt(count),
      });
      await expect(tx).to.be.revertedWith("SaleFacet: Sale is disabled");
    }
    {
      const tx = await preSaleFacet.connect(accounts[0]).setSaleIsActive(true);
      expect((await tx.wait()).status).to.be.equal(1);
    }
    for (let i = 0; i < 39; i++) {
      await helpers.purchaseRebels(preSaleFacet, account, 100);
    }
    {
      const count = 100 + 1;
      const tx = preSaleFacet.connect(account).purchaseDemRebels(count, {
        value: testCfg.demRebelSalePrice * BigInt(count),
      });
      await expect(tx).to.be.revertedWith(
        "SaleFacet: Second part mint reached max cap",
      );
    }
    await helpers.purchaseRebels(preSaleFacet, account, 100);
    {
      const isActive = await preSaleFacet.connect(account).isSaleActive();
      expect(isActive).to.be.equal(false);
    }
  });

  it("Should buy from whitelisted address", async () => {
    const account = accounts[1];
    const address = await account.getAddress();
    //console.log("account address", accounts[1].getAddress());
    {
      const tx = await preSaleFacet.setWhitelistActive(true);
      expect((await tx.wait()).status).to.be.equal(1);
    }
    {
      const root =
        "0x4ab7dfe706af9f8dd8da5e2e026e3ca332f10d64f8d8c2e9dc7e9e61e065d53f";
      const tx = await preSaleFacet.setWhitelistMerkleRoot(root);
      assert.equal((await tx.wait()).status, true, "root should be set");
    }
    {
      const proof = [
        "0xcac43c0291466ae54aa0b5f0d6f0faa97deb84693cf7664e857b86220880a388",
        "0xbf9f19376d0ac223168dbe9fab25bb273c0cf5e8b5b6ff1e84210004725d0a74",
      ];
      const count = 3;
      const tx = await preSaleFacet
        .connect(account)
        .whitelistSale(proof, count, {
          value: testCfg.whitelistSalePrice * BigInt(count),
        });
      assert.equal((await tx.wait()).status, true, "whitelistSale error");

      const tokenIds = await demRebel.connect(account).tokenIdsOfOwner(address);
      assert.equal(
        tokenIds.length,
        count + 5000,
        "error: tokenIds length after buy",
      );
    }
  });
});
