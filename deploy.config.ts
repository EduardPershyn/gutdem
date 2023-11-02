import {ethers} from "hardhat";

export let deployConfig = {
    dbnName: "DemBacon",
    dbnSymbol: "DBN",

    name: "TEST",
    symbol: "TT",
    maxDemRebels: 10000,
    demRebelSalePrice: ethers.parseEther("0.0008"),
    whitelistSalePrice: ethers.parseEther("0.0002"),
    maxDemRebelsSalePerUser: 10000,
    isSaleActive: true,
    cloneBoxURI: "ipfs://QmUzSR5yDqtsjnzfvfFZWe2JyEryhm7UgUfhKr9pkokG7C",

    //Cross Chain
    isRootChain: true,
    fxCheckpointManager: "0x2890bA17EfE978480615e330ecB65333b880928e",
    fxRoot: "0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA",
    fxChild: "0xCf73231F28B7331BBe3124B907840A94851f9f11",

    //Farm Nfts
    growerNftName: "GUTDEM Farm Grower",
    growerNftSymbol: "GDGRW",
    growerNftImage: "ipfs://QmUzSR5yDqtsjnzfvfFZWe2JyEryhm7UgUfhKr9pkokG7C",
    growerNftMax: 5000,
    growerSaleActive: true,
    growerSaleBcnPrice: ethers.parseEther("100"),

    toddlerNftName: "GUTDEM Farm Toddler",
    toddlerNftSymbol: "GDTDL",
    toddlerNftImage: "ipfs://QmUzSR5yDqtsjnzfvfFZWe2JyEryhm7UgUfhKr9pkokG7C",
    toddlerNftMax: 3000,
    toddlerSaleActive: true,
    toddlerSaleBcnPrice: ethers.parseEther("50"),
}