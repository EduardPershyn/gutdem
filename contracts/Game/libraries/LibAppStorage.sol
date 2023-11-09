// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LibDiamond} from "../../shared/diamond/lib/LibDiamond.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

//import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

struct RebelFarmInfo {
    bool isFarmActivated;
    bool isFarmStarted;
    uint256 farmTier;
    uint256 toddlerCount;
    uint256 growerCount;
    uint256 farmRate;
    uint256 harvestAmount;
    uint256 upgradeCooldown;

    bool isScoutInProgress;
    bool isScoutDone;
    uint256 scoutedFarm;
    bool isFarmRaidOngoing;
    bool isFarmRaidFinished;
    uint256 timeToFinishFarmRaid;
    uint256 activeToddlers;
}

struct RaidRequest {
    uint256 pivotFarm;
    uint256 raidSuccessChance;
}

struct AppStorage {
    mapping(address => bool) gameManagers;

    address demBaconAddress;
    address demRebelAddress;
    address demGrowerAddress;
    address demToddlerAddress;
    address safeAddress;

    //// Rebel Weed Farms
    uint256 farmPeriod;
    uint256 farmMaxTier;
    uint256 toddlerMaxCount;
//    uint256 basicLootShare;
    mapping(uint256 => uint256) farmTier;
    mapping(uint256 => uint256) farmHarvestedTime;
    mapping(uint256 => uint256) farmStockHarvest;
    mapping(uint256 => uint256) farmUpgradeTime;

    // Tier Indexes (only for started farms)
    mapping(uint256 => uint256[]) tierFarmIds;
    mapping(uint256 => mapping(uint256 => uint256)) tierFarmIdIndexes;

    //Nfts for Farm
    mapping(address => uint256[]) farmIdsForOwner;
    mapping(address => mapping(uint256 => uint256)) farmIdsForOwnerIndexes;
    mapping(uint256 => address) rebelInFarmOwner;
    mapping(uint256 => uint256[]) rebelFarmGrowers;
    mapping(uint256 => uint256[]) rebelFarmToddlers;

    //Raids
//    mapping(uint256 => uint256) scoutedFarm;
//    mapping(uint256 => bool) isScoutDone;
//    mapping(uint256 => bool) scoutInProgress;
//    uint256 farmRaidDuration;
    mapping(uint256 => uint256) toddlerInRaidQty;
//    mapping(uint256 => uint256) farmRaidStartTime;
//    mapping(bytes32 => RaidRequest) raidRequests;
//    mapping(bytes32 => uint256) scoutRequests;
    ////

    //FarmExchange
    uint256 initEpochPool; //first week constant
    uint256 remainingEpochPool;
//    //uint256 poolDecrease; //constant
    uint256 poolShareFactor; //param
    uint256 tokensMass;
    uint256 epochNumber;
    mapping(uint256 => mapping(uint256 => bool)) epochToFarmCashOut;
    uint256 tokensExchangeRate;
    ////

    //Lottery
//    bool isLotteryActive;
//    uint256 lotteryCount;
//    uint256 playersCount;
//    uint256[] players;
//    mapping(uint256 => uint256) playerToLottery;
//    bytes32 raffleRequestId;
//    uint256 prizeValue;
//
//    bytes32 vrfKeyHash;
//    uint256 vrfFee;
    ////

    //VRF
    //LinkTokenInterface LINK;
//    address vrfCoordinator;
//    // Nonces for each VRF key from which randomness has been requested.
//    // Must stay in sync with VRFCoordinator[_keyHash][this]
//    mapping(bytes32 => uint256) nonces; /* keyHash */ /* nonce */
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

    modifier onlyDemRebelOwner(uint256 tokenId_) {
        require(msg.sender == IERC721(s.demRebelAddress).ownerOf(tokenId_),
            "LibAppStorage: Only DemRebel owner");
        _;
    }

    modifier onlyOwner() {
        require(
            LibDiamond.contractOwner() == msg.sender,
            "LibAppStorage: Only owner"
        );
        _;
    }

    modifier onlyGameManager() {
        require(s.gameManagers[msg.sender], "LibAppStorage: Only Game manager");
        _;
    }

    modifier onlyFarmOwner(uint256 farmId_) {
        require(s.rebelInFarmOwner[farmId_] == msg.sender,
            "LibAppStorage: Only farm owner");
        _;
    }
}