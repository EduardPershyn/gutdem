import { ethers } from "hardhat";
import { strDisplay } from "./shared/utils";
import { deployConfig as cfg } from "../deploy.config";
import { deployConfig as testCfg } from "../deploy-test.config";

export async function main(
  isRoot: boolean,
  tests: boolean,
): Promise<[DeployedContracts]> {
  let totalGasUsed = 0n;
  let accounts = await ethers.getSigners();
  let account = await accounts[0].getAddress();

  if (!tests) console.log(`> Using account as owner: ${account}`);

  if (tests == true) {
    cfg = testCfg;
  }

  const dbnAddress = await demBaconDeploy();
  const [growerAddress, toddlerAddress] = await deployOnChildChain();

  if (!tests) console.log(`> Total gas used: ${strDisplay(totalGasUsed)}`);

  let result = new DeployedContracts({
    demBacon: dbnAddress,
    demRebel: "",
    game: "",
    growerDemNft: growerAddress,
    toddlerDemNft: toddlerAddress,
    safe: "",
    link: "",
  });
  return result;

  async function deployOnChildChain(): Promise<[string, string]> {
    let [growerNftArgs, growerSaleArgs, toddlerNftArgs, toddlerSaleArgs] =
      await deployFacets("DemNft", "SaleFacet", "DemNft", "SaleFacet");

    const growerAddress = await deployDiamond(
      "Grower DemNft",
      "contracts/DemNft/InitDiamond.sol:InitDiamond",
      [growerNftArgs, growerSaleArgs],
      [
        [
          cfg.growerNftName,
          cfg.growerNftSymbol,
          cfg.growerNftMax,
          cfg.growerNftImage,
          cfg.growerSaleActive,
          cfg.growerSaleBcnPrice,
          dbnAddress,
        ],
      ],
    );
    const toddlerAddress = await deployDiamond(
      "Toddler DemNft",
      "contracts/DemNft/InitDiamond.sol:InitDiamond",
      [toddlerNftArgs, toddlerSaleArgs],
      [
        [
          cfg.toddlerNftName,
          cfg.toddlerNftSymbol,
          cfg.toddlerNftMax,
          cfg.toddlerNftImage,
          cfg.toddlerSaleActive,
          cfg.toddlerSaleBcnPrice,
          dbnAddress,
        ],
      ],
    );

    {
      let demNftSale = await ethers.getContractAt(
        "SaleFacet",
        growerAddress,
        accounts[0],
      );
      let receipt = await (await demNftSale.setRewardManager(account)).wait();
      if (!tests)
        console.log(
          `>> growerNft setRewardManager gas used: ${strDisplay(
            receipt.gasUsed,
          )}`,
        );
      totalGasUsed += receipt.gasUsed;
    }
    {
      let demNftSale = await ethers.getContractAt(
        "SaleFacet",
        toddlerAddress,
        accounts[0],
      );
      let receipt = await (await demNftSale.setRewardManager(account)).wait();
      if (!tests)
        console.log(
          `>> toddlerNft setRewardManager gas used: ${strDisplay(
            receipt.gasUsed,
          )}`,
        );
      totalGasUsed += receipt.gasUsed;
    }

    return [growerAddress, toddlerAddress];
  }

  async function demBaconDeploy(): Promise<string> {
    const deployedDbn = await (
      await ethers.getContractFactory("DbnToken")
    ).deploy([account, cfg.dbnName, cfg.dbnSymbol]);
    await deployedDbn.waitForDeployment();
    const receipt = await deployedDbn.deploymentTransaction().wait();

    if (!tests) console.log(`>> demBacon address: ${receipt.contractAddress}`);
    if (!tests)
      console.log(
        `>> demBacon deploy gas used: ${strDisplay(receipt.gasUsed)}`,
      );
    totalGasUsed += receipt.gasUsed;

    let tx = await (await deployedDbn.setRewardManager(account)).wait();
    if (!tests)
      console.log(
        `>> demBacon setRewardManager gas used: ${strDisplay(tx.gasUsed)}`,
      );
    totalGasUsed += receipt.gasUsed;

    return receipt.contractAddress;
  }

  async function deployFacets(...facets: any): Promise<FacetArgs[]> {
    if (!tests) console.log("");

    const instances: FacetArgs[] = [];
    for (let facet of facets) {
      let constructorArgs = [];

      if (Array.isArray(facet)) {
        [facet, constructorArgs] = facet;
      }

      const factory = await ethers.getContractFactory(facet);
      const facetInstance = await factory.deploy(...constructorArgs);
      await facetInstance.waitForDeployment();
      const tx = facetInstance.deploymentTransaction();
      const receipt = await tx.wait();

      instances.push(
        new FacetArgs(facet, receipt.contractAddress, facetInstance),
      );

      if (!tests)
        console.log(`>>> Facet ${facet} deployed: ${receipt.contractAddress}`);
      if (!tests)
        console.log(`${facet} deploy gas used: ${strDisplay(receipt.gasUsed)}`);
      if (!tests) console.log(`Tx hash: ${tx.hash}`);

      totalGasUsed += receipt.gasUsed;
    }

    if (!tests) console.log("");

    return instances;
  }

  async function deployDiamond(
    diamondName: string,
    initDiamond: string,
    facets: FacetArgs[],
    args: any[],
  ): Promise<string> {
    let gasCost = 0n;

    const diamondCut = [];
    for (let facetArg of facets) {
      diamondCut.push([
        facetArg.address,
        FacetCutAction.Add,
        getSelectors(facetArg.contract),
      ]);
    }

    const deployedInitDiamond = await (
      await ethers.getContractFactory(initDiamond)
    ).deploy();
    await deployedInitDiamond.waitForDeployment();
    let receipt = await deployedInitDiamond.deploymentTransaction().wait();
    const deployedInitDiamondAddress = receipt.contractAddress;
    gasCost += receipt.gasUsed;

    const deployedDiamond = await (
      await ethers.getContractFactory("Diamond")
    ).deploy(account);
    await deployedDiamond.waitForDeployment();
    receipt = await deployedDiamond.deploymentTransaction().wait();
    gasCost += receipt.gasUsed;

    const diamondCutFacet = await ethers.getContractAt(
      "DiamondCutFacet",
      receipt.contractAddress,
    );
    const functionCall = deployedInitDiamond.interface.encodeFunctionData(
      "init",
      args,
    );
    const cutTx = await (
      await diamondCutFacet.diamondCut(
        diamondCut,
        deployedInitDiamondAddress,
        functionCall,
      )
    ).wait();
    gasCost += cutTx.gasUsed;

    if (!tests)
      console.log(
        `>> ${diamondName} diamond address: ${receipt.contractAddress}`,
      );
    if (!tests)
      console.log(
        `>> ${diamondName} diamond deploy gas used: ${strDisplay(gasCost)}`,
      );
    totalGasUsed += gasCost;

    return receipt.contractAddress;
  }
}

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2,
};

function getSelectors(contract: Contract) {
  const fragments = contract.interface.fragments;
  return fragments.reduce((acc: string[], val: ethers.Fragment) => {
    if (ethers.Fragment.isFunction(val)) {
      acc.push(val.selector);
    }
    return acc;
  }, []);
}

class FacetArgs {
  public name: string = "";
  public address: string;
  public contract: Contract;

  constructor(name: string, address: string, contract: Contract) {
    this.name = name;
    this.contract = contract;
    this.address = address;
  }
}

export class DeployedContracts {
  public demBacon: string = "";
  public demRebel: string = "";
  public game: string = "";
  public growerDemNft: string = "";
  public toddlerDemNft: string = "";
  public safe: string = "";
  public link: string = "";

  public constructor(init?: Partial<DeployedContracts>) {
    Object.assign(this, init);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main(cfg.isRootChain, false).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
