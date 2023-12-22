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

contract OpenZeppelinERC20Test is Test {
    OpenZeppelinERC20 token;

    function setUp() public {
        token = new OpenZeppelinERC20();
    }

    /** 
    *  @dev
    *   Commented out because _mint is internal and not visible to
    *   forge/hevm. To test it need to change to external or change
    *   logic (OpenZeppelin says it's fine to expose as external).
    *  Proves that minting changes balance as expected.
    */ 
    
    //function prove_balance(address usr, uint amt) public {
    //    assert(0 == token.balanceOf(usr));
    //    token._mint(usr, amt);
    //    assert(amt == token.balanceOf(usr));
    //}



}
