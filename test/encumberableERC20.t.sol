// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EncumberableERC20.sol";

contract EncumberableErc20Test is Test {
    event Encumber(address indexed owner, address indexed taker, uint encumberedAmount);
    event Release(address indexed owner, address indexed taker, uint releasedAmount);

    EncumberableERC20 public token;

    address alice = vm.addr(uint256(keccak256('alice')));
    address bob = vm.addr(uint256(keccak256('bob')));
    address charlie = vm.addr(uint256(keccak256('charlie')));


    function setUp() public  {
        token = new EncumberableERC20("Test", "eTest");
        token.mint(alice, 20e18);
        token.mint(bob, 20e18);

        vm.startPrank(alice);

        token.encumber(bob, 1e18);

        vm.stopPrank();
    }

    function testBlocksBasicTransfer() public {
        assertEq(token.encumberedBalanceOf(alice), 1e18);
        assertEq(token.encumbrances(alice, bob), 1e18);

        vm.startPrank(alice);

        vm.expectRevert(bytes("insufficient balance"));
        token.transfer(charlie, 20e18);

        token.transfer(charlie, 18e18);

        vm.stopPrank();

        assertEq(token.balanceOf(alice), 2e18);
    }

    function testReleasing() public {
        vm.startPrank(bob);
        token.release(alice, 0.5e18);

        assertEq(token.encumberedBalanceOf(alice), 0.5e18);
        assertEq(token.encumbrances(alice, bob), 0.5e18);
    }

    function testEvents() public {
        vm.startPrank(bob);

        assertEq(token.encumberedBalanceOf(alice), 1e18);
        assertEq(token.encumbrances(alice, bob), 1e18);

        vm.expectEmit(true, true, false, true, address(token));
        emit Release(alice, bob, 0.4e18);
        token.release(alice, 0.4e18);

        vm.stopPrank();
        vm.startPrank(alice);
        
        vm.expectEmit(true, true, false, true, address(token));
        emit Encumber(alice, bob, 0.2e18);
        
        token.encumber(bob, 0.2e18);
        vm.stopPrank();
    }
}