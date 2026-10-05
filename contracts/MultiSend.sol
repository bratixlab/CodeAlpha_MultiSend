// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

/// @title Multi-Send
/// @notice CodeAlpha Task 2 — sends an equal amount of Ether to a list of addresses
contract MultiSend {
    event Sent(address indexed recipient, uint256 amount);
    event MultiSendCompleted(uint256 totalRecipients, uint256 totalSent);

    error NoRecipients();
    error InsufficientValue();
    error TransferFailed(address recipient);

    /// @notice Splits msg.value equally among all given addresses and sends it
    /// @param recipients The list of addresses to pay
    function multiSendEqual(address payable[] calldata recipients) external payable {
        uint256 count = recipients.length;
        if (count == 0) revert NoRecipients();

        uint256 amountEach = msg.value / count;
        if (amountEach == 0) revert InsufficientValue();

        uint256 totalSent = 0;

        for (uint256 i = 0; i < count; i++) {
            (bool success, ) = recipients[i].call{value: amountEach}("");
            if (!success) revert TransferFailed(recipients[i]);
            totalSent += amountEach;
            emit Sent(recipients[i], amountEach);
        }

        uint256 leftover = msg.value - totalSent;
        if (leftover > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: leftover}("");
            if (!refunded) revert TransferFailed(msg.sender);
        }

        emit MultiSendCompleted(count, totalSent);
    }
}
