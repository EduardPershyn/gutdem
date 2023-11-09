// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibFarmCalc} from "../libraries/LibFarmCalc.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ISafe} from "../interfaces/ISafe.sol";

contract CashOut is Modifiers {
    function startNewCashOutEpoch(
        uint256 tokensMass_,
        uint256 exchangeRate_
    ) external onlyOwner {
        s.tokensMass = tokensMass_;
        s.tokensExchangeRate = exchangeRate_;

        uint256 newInitEpochPool = LibFarmCalc.dbnPoolDecrease(s.initEpochPool);
        s.initEpochPool = newInitEpochPool;
        s.remainingEpochPool = newInitEpochPool;

        s.epochNumber += 1;
    }

    /**
     * Exchange all available tokens in Farm Safe for Dbn tokens.
     * Could also be limited by other factors.
     * Takes one of Min(remaining dbn in pool, farm pool share, farm harverst tokens)
     */
    function cashOut(uint256 id_) external onlyFarmOwner(id_) {
        require(
            s.epochToFarmCashOut[s.epochNumber][id_] == false,
            "RebelFarm: Farm already cash out on this epoch!"
        );
        require(s.remainingEpochPool > 0, "RebelFarm: Token pool is empty!");

        uint256 tokensInSafe = ISafe(s.safeAddress).getSafeContent(id_);
        require(tokensInSafe > 0, "RebelFarm: Farm Safe is empty!");

        uint256 tokenToSpend;
        uint256 dbnAmount;
        (tokenToSpend, dbnAmount) = LibFarmCalc.farmTokenToDbnSwapPair(
            s.remainingEpochPool,
            s.initEpochPool,
            s.poolShareFactor,
            tokensInSafe,
            s.tokensMass,
            s.tokensExchangeRate
        );
        if (dbnAmount > 0) {
            //TODO mint dbn here?
            IERC20(s.demBaconAddress).transferFrom(
                s.safeAddress,
                msg.sender,
                dbnAmount
            ); //TODO ??
            s.remainingEpochPool -= dbnAmount;

            ISafe(s.safeAddress).reduceSafeEntry(id_, tokenToSpend);
            s.epochToFarmCashOut[s.epochNumber][id_] = true;
        }
    }

    function getTokenDbnSwapPair(
        uint256 id_
    ) external view returns (uint256 tokenToSpend, uint256 dbnAmount) {
        require(
            s.epochToFarmCashOut[s.epochNumber][id_] == false,
            "RebelFarmFacet: Farm already cash out on this epoch!"
        );
        require(
            s.remainingEpochPool > 0,
            "RebelFarmFacet: Token pool is empty!"
        );

        uint256 tokensInSafe = ISafe(s.safeAddress).getSafeContent(id_);
        require(tokensInSafe > 0, "RebelFarmFacet: Farm Safe is empty!");

        return
            LibFarmCalc.farmTokenToDbnSwapPair(
                s.remainingEpochPool,
                s.initEpochPool,
                s.poolShareFactor,
                tokensInSafe,
                s.tokensMass,
                s.tokensExchangeRate
            );

        //        return LibFarmCalc.farmTokenToDbnSwapPair(995_000 ether, 995_000 ether, 1.5 ether,
        //            100_000 ether, 1_300_000 ether, 5 ether);

        //        return LibFarmCalc.farmTokenToDbnSwapPair(114_000, 995_000, 1.5 ether,
        //            100_000, 1_300_000, 5 ether);
    }

    function isFarmCashOut(uint256 _farmId) external view returns (bool) {
        return s.epochToFarmCashOut[s.epochNumber][_farmId];
    }

    function buyFarmTokens(
        uint256 _farmId,
        uint256 _dbnAmount
    ) external onlyFarmOwner(_farmId) {
        IERC20(s.demBaconAddress).transferFrom(
            msg.sender,
            s.safeAddress,
            _dbnAmount
        );

        uint256 farmTokensAmount = LibFarmCalc.dbnToFarmTokens(
            _dbnAmount,
            s.tokensExchangeRate
        );
        ISafe(s.safeAddress).increaseSafeEntry(_farmId, farmTokensAmount);
    }

    function getFarmTokensAmountFromDbn(
        uint256 _dbnAmount
    ) external view returns (uint256) {
        return LibFarmCalc.dbnToFarmTokens(_dbnAmount, s.tokensExchangeRate);
    }

    function getRemainingEpochPool() external view returns (uint256) {
        return s.remainingEpochPool;
    }

    function getInitEpochPool() external view returns (uint256) {
        return s.initEpochPool;
    }

    function getPoolShareFactor() external view returns (uint256) {
        return s.poolShareFactor;
    }

    function setPoolShareFactor(uint256 factor_) external onlyOwner {
        s.poolShareFactor = factor_;
    }
}
