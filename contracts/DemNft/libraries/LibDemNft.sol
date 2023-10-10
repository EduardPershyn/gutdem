// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibERC721} from "../../shared/libraries/LibERC721.sol";

library LibDemNft {
    function tokenBaseURI(
        uint256 tokenId_
    ) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        string storage baseURI = s.baseURI;

        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, Strings.toString(tokenId_))
                : s.cloneBoxURI;
    }

    function setOwner(uint256 id_, address newOwner_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldOwner = s.owners[id_];
        uint256[] storage ownerTokenIds = s.ownerTokenIds[newOwner_];

        s.owners[id_] = newOwner_;
        s.ownerTokenIdIndexes[newOwner_][id_] = ownerTokenIds.length;
        ownerTokenIds.push(id_);

        emit LibERC721.Transfer(oldOwner, newOwner_, id_);
    }

    function transfer(address from_, address to_, uint256 tokenId_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256[] storage ownerTokenIdsFrom = s.ownerTokenIds[from_];
        mapping(uint256 => uint256) storage ownerTokenIdIndexesFrom = s
            .ownerTokenIdIndexes[from_];

        //remove index
        uint256 index = ownerTokenIdIndexesFrom[tokenId_];
        uint256 lastIndex = ownerTokenIdsFrom.length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = ownerTokenIdsFrom[lastIndex];
            ownerTokenIdsFrom[index] = lastTokenId;
            ownerTokenIdIndexesFrom[lastTokenId] = index;
        }
        ownerTokenIdsFrom.pop();
        delete ownerTokenIdIndexesFrom[tokenId_];

        //remove approval
        if (s.approved[tokenId_] != address(0)) {
            delete s.approved[tokenId_];
            emit LibERC721.Approval(from_, address(0), tokenId_);
        }

        // add index
        setOwner(tokenId_, to_);
    }
}
