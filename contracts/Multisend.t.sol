// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import {MultiSend} from "./MultiSend.sol";
import {Test} from "forge-std/Test.sol";

contract MultiSendTest is Test {
    MultiSend multiSend;

    address payable alice;
    address payable bob;
    address payable carol;

    function setUp() public {
        multiSend = new MultiSend();
        alice = payable(makeAddr("alice"));
        bob = payable(makeAddr("bob"));
        carol = payable(makeAddr("carol"));
    }

    function test_SendsEqualAmountsToAllRecipients() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = carol;

        multiSend.multiSendEqual{value: 3 ether}(recipients);

        require(alice.balance == 1 ether, "alice should receive 1 ether");
        require(bob.balance == 1 ether, "bob should receive 1 ether");
        require(carol.balance == 1 ether, "carol should receive 1 ether");
    }

    function test_RefundsDustFromUnevenDivision() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = carol;

        uint256 senderBalanceBefore = address(this).balance;

        // 10 wei / 3 recipients = 3 wei each, 1 wei left over as dust
        multiSend.multiSendEqual{value: 10}(recipients);

        require(alice.balance == 3, "alice should receive 3 wei");
        require(bob.balance == 3, "bob should receive 3 wei");
        require(carol.balance == 3, "carol should receive 3 wei");
        require(address(this).balance == senderBalanceBefore - 9, "sender should get 1 wei dust back");
    }

    function test_RevertsWithNoRecipients() public {
        address payable[] memory recipients = new address payable[](0);
        vm.expectRevert(MultiSend.NoRecipients.selector);
        multiSend.multiSendEqual{value: 1 ether}(recipients);
    }

    function test_RevertsWithInsufficientValue() public {
        address payable[] memory recipients = new address payable[](5);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = carol;
        recipients[3] = alice;
        recipients[4] = bob;

        // 1 wei split across 5 recipients rounds down to 0 each
        vm.expectRevert(MultiSend.InsufficientValue.selector);
        multiSend.multiSendEqual{value: 1}(recipients);
    }

    receive() external payable {}
}
