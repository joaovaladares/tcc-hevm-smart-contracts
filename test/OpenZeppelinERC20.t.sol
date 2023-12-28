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
    *  transfer to address 0 should fail and revert.
    */ 
    function proveFail_transferToZeroAddress(uint256 amt) public {
        token._mint(address(this), amt);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        bool r = token.transfer(address(0), amt);
        assertWithMsg(r == false, "Successful transfer to address zero");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-02 implementation
    *  transfer should fail if account balance is lower than the total amt
    *  trying to be sent.
    */ 
    function proveFail_transferNotEnoughBalance(address to, uint256 amt ) public {
        token._mint(address(this), amt - 1);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        bool r = token.transfer(to, amt - 1); // Should revert inside transfer function
        assertWithMsg(r == false, "Transfered even though address had not enough balance.");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *  transfer should transfer the right amount in non-self transfers and pass
    *  if the amt subtracted from sender is correct and the added value to usr
    *  balance is also amt.
    */  
    function prove_transfer(uint256 supply, address usr, uint256 amt) public {
        require(usr != address(0));
        token._mint(address(this), supply);
        require(amt <= token.balanceOf(address(this)));
        require(token.balanceOf(usr) + amt < type(uint256).max); //no overflow on receiver

        uint256 prebal = token.balanceOf(usr);
        token.transfer(usr, amt);
        uint256 postbal = token.balanceOf(usr);

        uint256 expected = usr == address(this)
                        ? 0     // no self transfer allowed here
                        : amt;  // otherwise amt has been transfered to usr
        assert(expected == postbal - prebal);    
    } 

    /** 
    *  @dev
    *  property ERC20-STDPROP-04 implementation
    *  transfer can succeed in self transfers if the amt doesn't exceeds the
    *  current balance of msg.sender
    */ 
    function prove_transferToSelf(uint256 amt) public {
        token._mint(address(this), amt);
        uint256 prebal = token.balanceOf(address(this));
        require(prebal > 0);

        token.transfer(address(this), amt);

        uint256 postbal = token.balanceOf(address(this));
        assertEq(prebal, postbal);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-05 implementation
    *  zero amount transfer should not break accounting
    */ 
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

    /** 
    *  @dev
    *  property ERC20-STDPROP-06 implementation
    *  transferFrom coming from address 0 should fail and revert.
    */ 
    function proveFail_transferFromZeroAddress(address from, address to, uint256 amt) public {
        require(from == address(0));
        require(to != address(0));
        bool r = token.transferFrom(from, to, amt);
        assertWithMsg(r == false, "transferFrom coming from zero address success");
        assert(r != true);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-07 implementation
    *  transferFrom to address 0 should fail and revert.
    */ 
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

    /** 
    *  @dev
    *  property ERC20-STDPROP-08 implementation
    *  transferFrom should revert if not enough balance available
    */ 
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

    /** 
    *  @dev
    *  property ERC20-STDPROP-09 implementation
    *  transferFrom should update accounting accordingly when succeeding
    */ 
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
}
