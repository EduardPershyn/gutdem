import {ethers} from "hardhat";

export let deployConfig = {
    dbnName: "DemBacon",
    dbnSymbol: "DBN",

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