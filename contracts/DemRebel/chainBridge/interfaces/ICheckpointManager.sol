// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

interface IFxStateSender {
    function sendMessageToChild(
        address _receiver,
        bytes calldata _data
    ) external;
}
