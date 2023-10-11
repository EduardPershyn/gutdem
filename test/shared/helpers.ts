import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { Contract, Signer } from "ethers";
import { deployConfig as testCfg } from "../../deploy-test.config";

let helpers = {
  mintDemBacon: async (
    owner: Signer,
    account: Signer,
    dbnFacet: Contract,
    amount: BigInt,
  ) => {
    let accountAddress = await account.getAddress();
    {
      let tx = await dbnFacet.connect(owner).mint(accountAddress, amount);
      let receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should mint demBacon");
    }
  },

  buyGrowers: async (
    owner: Signer,
    account: Signer,
    grwsCount: BigInt,
    dbnFacet: Contract,
    growerNftFacet: Contract,
  ) => {
    let accountAddress = await account.getAddress();
    let totalPrice = testCfg.growerSaleBcnPrice * BigInt(grwsCount);

    await helpers.mintDemBacon(owner, account, dbnFacet, totalPrice);
    let balanceBefore = await growerNftFacet.balanceOf(accountAddress);
    {
      //Use ERC1363 to obtain growers
      let tx = await dbnFacet
        .connect(account)
        .transferAndCall(growerNftFacet.target, totalPrice);
      let receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should approve demBacon");
    }
    let balanceAfter = await growerNftFacet.balanceOf(accountAddress);
    expect(balanceAfter - balanceBefore).to.be.equal(
      grwsCount,
      "Buy obtain failed",
    );
  },

  errorMessage: (e: any) => {
    let message = "";
    if (typeof e === "string") {
      message = e.toUpperCase();
    } else if (e instanceof Error) {
      message = e.message;
    }
    return message;
  },

  expectTxError: async (tx: string, errorMsg: string) => {
    try {
      await tx;
      expect(true, "promise should fail").eq(false);
    } catch (e) {
      let message = helpers.errorMessage(e);
      //console.log(message);
      expect(message).includes(errorMsg);
    }
  },
};

export { helpers };
