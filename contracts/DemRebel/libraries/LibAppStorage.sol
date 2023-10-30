// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LibDiamond} from "../../shared/diamond/lib/LibDiamond.sol";
import {ICheckpointManager, IFxStateSender} from "../chainBridge/interfaces/ICheckpointManager.sol";

struct DemRebelData {
    string name;
    address owner;
}

struct AppStorage {
    uint256 maxDemRebels;
    uint256 maxDemRebelsSalePerUser;
    uint256 demRebelSalePrice;
    bool isSaleActive;
    string name;
    string symbol;
    uint256 tokenIdsCount;

    bytes32 whitelistMerkleRoot;
    uint256 whitelistSalePrice;
    mapping(address => bool) whitelistClaimed;
    bool isWhitelistActive;

    mapping(uint256 => DemRebelData) demRebels;
    mapping(address => uint256[]) ownerTokenIds;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    mapping(uint256 => address) approved;
    mapping(address => mapping(address => bool)) operators;
    mapping(string => bool) demRebelNamesUsed;

    string baseURI1;
    string baseURI2;
    string baseURI3;
    string cloneBoxURI;

    // Bridge related
    ICheckpointManager checkpointManager;
    IFxStateSender fxRoot;
    address fxChild;
    address fxRootTunnel;
    address fxChildTunnel;
    mapping(bytes32 => bool) processedExits;
    mapping (address => address) reflection;
    bool isRootChain;
}


library LibAppStorage {
    function diamondStorage() internal pure returns(AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyDemRebelOwner(uint256 _tokenId) {
        require(msg.sender == s.demRebels[_tokenId].owner, "LibAppStorage: Only DemRebel owner");
        _;
    }

    modifier onlyOwner() {
        require(
            LibDiamond.contractOwner() == msg.sender,
            "LibAppStorage: Only owner"
        );
        _;
    }
}
