// SPDX-License-Identifier: MIT

/** 
*   @dev
*   This file is meant to implement the tests for 
*   OpenZeppelin's ERC20 token standard implementation
*   in order to show that it satisfies the properties
*   defined for our research. 
*   Those properties will be listed out in a README.md
*   in the 'test/' folder of this repository, please notice
*   that it's not possible yet to have many properties tested
*   because of time limit of my part.
*/

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OpenZeppelinERC20} from "src/OpenZeppelinERC20.sol";
import "test/PropertiesHelper.sol";

contract OpenZeppelinERC20Test is Test, PropertiesAsserts {
    OpenZeppelinERC20 token;

    function setUp() public {
        token = new OpenZeppelinERC20(); 
    }

    /** 
    *  @dev
    *  Proves that minting changes balance as expected.
    */ 
    // function prove_balance(address usr, uint256 amt) public {
    //    assert(0 == token.balanceOf(usr));
    //    token._mint(usr, amt);
    //    assert(amt == token.balanceOf(usr));
    // }

    /** 
    *  @dev
    *  property ERC20-STDPROP-01 implementation
    *
    *  transfer succeeds if the following conditions are met:
    *  - the 'to' address is not the zero address
    *  - amt does not exceed the balance of msg.sender (address(this)) 
    *  - transfering amt to 'to' address does not results in a overflow  
    */  
    function prove_transfer(uint256 supply, address to, uint256 amt) public {
        require(to != address(0));
        token._mint(address(this), supply);
        require(amt <= token.balanceOf(address(this)));
        require(token.balanceOf(to) + amt < type(uint256).max); //no overflow on receiver
        
        uint256 prebal = token.balanceOf(to);
        bool success = token.transfer(to, amt);
        uint256 postbal = token.balanceOf(to);

        uint256 expected = to == address(this)
                        ? 0     // no self transfer allowed here
                        : amt;  // otherwise amt has been transfered to to
        assertTrue(expected == postbal - prebal, "Incorrect expected value returned");
        assertTrue(success, "Transfer function failed");
    } 

    /** 
    *  @dev
    *  property ERC20-STDPROP-02 implementation
    *
    *  transfer can succeed in self transfers if the following is met:
    *  - amt does not exceeds the balance of msg.sender (address(this))
    */ 
    function prove_transferToSelf(uint256 amt) public {
        require(amt > 0);
        token._mint(address(this), amt);
        uint256 prebal = token.balanceOf(address(this));
        require(prebal >= amt);

        bool success = token.transfer(address(this), amt);

        uint256 postbal = token.balanceOf(address(this));
        assertEq(prebal, postbal, "Value of prebal and postbal doesn't match");
        assertTrue(success, "Self transfer failed");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  transfer should send the correct amount in Non-self transfers:
    *  - if a transfer call returns true (doesn't revert), it must subtract the value 'amt'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferCorrectAmount(address to, uint256 amt) public {
        require(amt > 1);
        require(to != address(this));
        token._mint(address(this), amt);
        uint256 prebalSender = token.balanceOf(address(this));
        uint256 prebal_receiver = token.balanceOf(to);
        require(prebalSender > 0);

        bool success = token.transfer(to, amt);
        uint256 postbalSender = token.balanceOf(address(this));
        uint256 postbalReceiver = token.balanceOf(to);

        assert(postbalSender == prebalSender - amt);
        assert(postbalReceiver == prebalReceiver + amt);
        assert(success);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-04 implementation
    *
    *  transfer should send correct amount in self-transfers:
    *  - if a self-transfer call returns true (doesn't revert), it must subtract the value 'amt'
    *  - from the msg.sender and add that same value to the 'to' address
    */ 
    function prove_transferSelfCorrectAmount(uint256 amt) public {
        require(amt > 1);
        require(amt != UINT256_MAX);
        token._mint(address(this), amt);
        uint256 prebalSender = token.balanceOf(address(this));
        require(prebalSender > 0);

        bool success = token.transfer(address(this), amt);
        uint256 postbalSender = token.balanceOf(address(this));

        assertTrue(postbalSender == prebalSender);
        assertTrue(success);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-05 implementation
    *
    *  transfer should not have any unexpected state changes on non-revert calls as follows:
    *  - must only modify the balance of msg.sender (caller) and the address 'to' the transfer is being made 
    *  - any other state e.g. allowance, totalSupply, balances of an address not involved in the transfer call
    *  - should not change 
    */ 
    function prove_transferChangeState(address to, uint256 amt) public {
        require(amt > 0);
        require(to != address(0));
        require(to != msg.sender);
        require(msg.sender != address(0));
        token._mint(msg.sender, amt);
        require(token.balanceOf(msg.sender) > 0);

        //Create an address that is not involved in the transfer call
        address addr = address(bytes20(keccak256(abi.encode(block.timestamp))));
        require(addr != address(0));
        require(addr != msg.sender);
        require(addr != to);
        token._mint(addr, amt);

        uint256 initialSupply = token.totalSupply();
        uint256 senderInitialBalance = token.balanceOf(msg.sender);
        uint256 receiverInitialBalance = token.balanceOf(to);

        uint256 addrInitialBalance = token.balanceOf(addr);
        uint256 allowanceForAddr = 100;
        token.approve(addr, allowanceForAddr);
        uint256 addrInitialAllowance = token.allowance(address(this), addr);
        
        bool success = token.transfer(to, amt);
        require(success, "Transfer failed!");

        assert(token.balanceOf(msg.sender) == senderInitialBalance - amt);
        assert(token.balanceOf(to) == receiverInitialBalance + amt);

        assert(token.totalSupply() == initialSupply);
        assert(token.balanceOf(addr) == addrInitialBalance);
        assert(token.allowance(address(this), addr) == addrInitialAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  any transfer call to address 0 should fail and revert.
    */ 
    function proveFail_transferToZeroAddress(uint256 supply, uint256 amt) public {
        require(supply > 0);
        require(amt > 0);
        token._mint(address(this), supply);
        require(amt <= supply, "Amount exceeds supply!");
        uint prebal = token.balanceOf(address(this));

        //Should revert on transfer
        bool success = token.transfer(address(0), amt);

        //If it doesn't revert, we reach the assertion and test fails
        uint postbal = token.balanceOf(address(this));
        assert(success);
        assert(prebal != postbal);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  transfer should fail if account balance is lower than the total amt
    *  trying to be sent.
    */ 
    function proveFail_transferNotEnoughBalance(address to, uint256 amt) public {
        require(amt > 1);
        token._mint(address(this), amt - 1);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        bool success = token.transfer(to, amt); // Should revert inside transfer function
        assertTrue(success, "Transfer succeeded with amt higher than balance");
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-05 implementation
    // *  zero amount transfer should not break accounting
    // */ 
    function prove_transferZeroAmount(address usr) public {
        token._mint(address(this), 1);
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(usr);
        require(balance_sender > 0);

        bool r = token.transfer(usr, 0);
        assertWithMsg(r == true, "Zero amount transfer not succeeded");
        assertEq(token.balanceOf(address(this)), balance_sender);
        assertEq(token.balanceOf(usr), balance_receiver);
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-06 implementation
    // *  transferFrom coming from address 0 should fail and revert.
    // */ 
    function proveFail_transferFromZeroAddress(address from, address to, uint256 amt) public {
        require(from == address(0));
        require(to != address(0));
        bool r = token.transferFrom(from, to, amt);
        assertWithMsg(r == false, "transferFrom coming from zero address success");
        assert(r != true);
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-07 implementation
    // *  transferFrom to address 0 should fail and revert.
    // */ 
    function proveFail_transferFromToZeroAddress(uint256 amt) public {
        token._mint(msg.sender, amt);
        uint256 sender_balance = token.balanceOf(msg.sender);
        uint256 sender_allowance = token.allowance(msg.sender, address(this));
        require(sender_balance > 0 && sender_allowance > 0);
        uint256 maxAmt = sender_balance >= sender_allowance
                        ? sender_allowance
                        : sender_balance;

        bool r = token.transferFrom(msg.sender, address(0), amt % (maxAmt + 1));
        assertWithMsg(r == false, "transferFrom to address zero sucess");
        assert(r != true);
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-08 implementation
    // *  transferFrom should revert if not enough balance available
    // */ 
    function proveFail_transferFromNotEnoughBalance(address usr, uint256 amt) public {
        token._mint(msg.sender, amt);
        uint256 sender_balance = token.balanceOf(msg.sender);
        uint256 usr_balance = token.balanceOf(usr);
        uint256 sender_allowance = token.allowance(msg.sender, address(this));
        require(sender_balance > 0 && sender_allowance > sender_balance);

        bool r = token.transferFrom(msg.sender, usr, sender_balance + 1);
        assertWithMsg(r == false, "transferFrom with more than account balance success.");
        assertEq(token.balanceOf(msg.sender), sender_balance);
        assertEq(token.balanceOf(usr), usr_balance);
    }

    // /** 
    // *  @dev
    // *  property ERC20-STDPROP-09 implementation
    // *  transferFrom should update accounting accordingly when succeeding
    // */ 
    function prove_transferFrom(address usr, uint256 amt) public {
        require(usr != address(this));
        require(usr != msg.sender);
        //token._mint(msg.sender, amt + 10);
        uint256 sender_balance = token.balanceOf(msg.sender);
        uint256 usr_balance = token.balanceOf(usr);
        uint256 sender_allowance = token.allowance(msg.sender, address(this));
        require(sender_balance > 2 && sender_allowance > sender_balance);
        uint256 transfer_amt = (amt % sender_balance) + 1;
        require(token.balanceOf(usr) + transfer_amt < type(uint256).max); //no overflow on receiver

        bool r = token.transferFrom(msg.sender, usr, transfer_amt);
        assertWithMsg(r == true, "transferFrom not succeeded");
        assertEq(token.balanceOf(msg.sender), sender_balance - transfer_amt);
        assertEq(token.balanceOf(usr), usr_balance + transfer_amt);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-10 implementation
    *  transfer should not return false on failure, instead it should revert
    *
    *  in the implementation below, we supose that the token implementation doesn't allow
    *  transfer with amt higher than the supply (balanceOf(address(this)) will be equal to supply)
    */ 
    function proveFail_transferShouldRevertOnFailure(address to, uint supply, uint amt) public {
        require(to != address(0));
        require(to != address(this));
        token._mint(address(this), supply);
        require(amt > 0, "Amount should not be zero");
        require(amt > supply, "Amount should be greater than supply for failure");

        // Attempt the transfer and store the return value
        bool success = token.transfer(to, amt);

        // The assert statement will only be reached if the transfer does not revert
        // Since we expect a revert on failure, reaching this line means the test should fail
        assert(success == false);
    }   
}
