// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibDemNft} from "../libraries/LibDemNft.sol";

contract SaleFacet is Modifiers, IERC1363Receiver {
    function setRewardManager(address rewardManager_) external onlyOwner {
        s.rewardManager = rewardManager_;
        IERC20(s.dbnContract).approve(rewardManager_, type(uint256).max);
    }

    function withdrawDbn() external onlyRewardManager {
        IERC20(s.dbnContract).transferFrom(
            address(this),
            msg.sender,
            IERC20(s.dbnContract).balanceOf(address(this))
        );
    }

    function onTransferReceived(
        address operator,
        address,
        uint256 amount,
        bytes memory
    ) external override returns (bytes4) {
        require(
            msg.sender == address(s.dbnContract),
            "SaleFacet: onTransferReceived wrong sender"
        );
        require(s.isSaleEnabled == true, "SaleFacet: Purchase is disabled");

        uint256 nftAmount = s.dbnPrice / amount;
        require(nftAmount > 0, "SaleFacet: Too low amount");
        _mint(nftAmount, operator);

        return IERC1363Receiver.onTransferReceived.selector;
    }

    function _mint(uint256 amount_, address to_) internal {
        uint256 tokenId = s.tokenIdsCount;
        require(
            tokenId + amount_ <= s.maxNftCount,
            "SaleFacet: Exceed max nft supply"
        );

        for (uint256 i = 0; i < amount_; ) {
            LibDemNft.setOwner(tokenId, to_);

            unchecked {
                ++tokenId;
                ++i;
            }
        }
        s.tokenIdsCount = tokenId;
    }
}
