// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LibDemRebel} from "../libraries/LibDemRebel.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";

contract PreSaleFacet is Modifiers {
    function isSaleActive() external view returns (bool) {
        return s.isSaleActive;
    }

    function setSaleIsActive(bool isActive_) external onlyOwner {
        s.isSaleActive = isActive_;
    }

    function isWhitelistActive() external view returns (bool) {
        return s.isWhitelistActive;
    }

    function isClaimed(address owner_) external view returns (bool) {
        return s.whitelistClaimed[owner_];
    }

    function setWhitelistActive(bool isActive_) external onlyOwner {
        s.isWhitelistActive = isActive_;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        s.whitelistMerkleRoot = merkleRoot_;
    }

    function maxDemRebelsSalePerUser() external view returns (uint256) {
        return s.maxDemRebelsSalePerUser;
    }

    function setMaxDemRebelsSalePerUser(uint256 maxDemRebelsSalePerUser_) external onlyOwner {
        s.maxDemRebelsSalePerUser = maxDemRebelsSalePerUser_;
    }

    function whitelistSale(
        bytes32[] calldata proof,
        uint256 count_
    ) external payable {
        // Merkle tree list related
        require(s.isWhitelistActive, "SaleFacet: Whitelist sale is disabled");
        require(
            s.whitelistClaimed[msg.sender] == false,
            "SaleFacet: Address already used whitelist sale"
        );
        require(
            s.whitelistMerkleRoot != "",
            "SaleFacet: Whitelist claim merkle root not set"
        );
        require(
            MerkleProof.verify(
                proof,
                s.whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, count_))
            ),
            "SaleFacet: Whitelist claim validation failed"
        );

        // Go mint
        require(
            s.whitelistSalePrice * count_ <= msg.value,
            "SaleFacet: Insufficient ethers value"
        );
        mint(count_);

        s.whitelistClaimed[msg.sender] = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "SaleFacet: Withdraw failed");
    }

    function purchaseDemRebels(uint256 count_) external payable {
        require(s.isSaleActive, "SaleFacet: Sale is disabled");
        require(
            s.demRebelSalePrice * count_ <= msg.value,
            "SaleFacet: Insufficient ethers value"
        );
        mint(count_);
    }

    function mint(uint256 rebelsCount_) internal virtual {
        require(s.isRootChain == true, "SaleFacet: Mint allowed only from L1");
        require(
            rebelsCount_ + s.tokenIdsCount <= s.maxDemRebels,
            "SaleFacet: Exceeded maximum DemRebels supply"
        );
        require(
            rebelsCount_ + s.ownerTokenIds[msg.sender].length <=
                s.maxDemRebelsSalePerUser,
            "SaleFacet: Exceeded maximum DemRebels per user"
        );

        checkMintLimit(rebelsCount_);

        uint256 tokenId = s.tokenIdsCount;
        for (uint256 i = 0; i < rebelsCount_; ) {
            LibDemRebel.setOwner(tokenId, msg.sender);

            unchecked {
                ++tokenId;
                ++i;
            }
        }
        s.tokenIdsCount = tokenId;
    }

    function checkMintLimit(uint256 requestedCount_) internal {
        // We don't want to overlap level, cause we consider to change price on new level
        require(
            s.tokenIdsCount >= LibDemRebel.FIRST_MINT_LIMIT ||
                s.tokenIdsCount + requestedCount_ <=
                LibDemRebel.FIRST_MINT_LIMIT,
            "SaleFacet: First part mint reached max cap"
        );
        require(
            s.tokenIdsCount >= LibDemRebel.SECOND_MINT_LIMIT ||
                s.tokenIdsCount + requestedCount_ <=
                LibDemRebel.SECOND_MINT_LIMIT,
            "SaleFacet: Second part mint reached max cap"
        );

        // Stop mint if some of the cap levels reached
        if (s.tokenIdsCount + requestedCount_ == LibDemRebel.FIRST_MINT_LIMIT) {
            s.isSaleActive = false;
            s.isWhitelistActive = false;
        } else if (
            s.tokenIdsCount + requestedCount_ == LibDemRebel.SECOND_MINT_LIMIT
        ) {
            s.isSaleActive = false;
            s.isWhitelistActive = false;
        }
    }
}
