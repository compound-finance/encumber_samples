// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EncumberableERC20.sol";
import "../src/OptionalPurchase.sol";

contract OptionalPurchaseTest is Test {
    event Encumber(address indexed owner, address indexed taker, uint encumberedAmount);
    event Release(address indexed owner, address indexed taker, uint releasedAmount);

    EncumberableERC20 public token;
    OptionalPurchase public optionalPurchase;

    address alice = vm.addr(uint256(keccak256('alice')));
    address bob = vm.addr(uint256(keccak256('bob')));
    address charlie = vm.addr(uint256(keccak256('charlie')));

    function setUp() public  {
        token = new EncumberableERC20("Test", "eTest");
        token.mint(bob, 20e18);
        vm.deal(alice, 10 ether);

        optionalPurchase = new OptionalPurchase();

        vm.startPrank(bob);
        token.encumber(address(optionalPurchase), 5e18);
        uint theId = optionalPurchase.offerOption(address(token), 0.1 ether, 0.8 ether, block.timestamp + 1000);
        assertEq(theId, uint(0));
        assertEq(token.encumbrances(bob, address(optionalPurchase)), 5e18);

        vm.stopPrank();
    }

    function testOfferingTheOption() public {
        (address offeredToken,
        uint holdPrice,
        uint purchasePrice,
        uint size,
        uint expiration,
        address payable writer) = optionalPurchase.offersById(uint(0));

        assertEq(address(token), offeredToken);
        assertEq(holdPrice, (0.1 ether));
        assertEq(purchasePrice, (0.8 ether));

        // Note size was not passed in, and is instead equal to the existing encumbrance to the contract!
        assertEq(size, 5e18);
        assertEq(expiration, block.timestamp + 1000);
        assertEq(writer, payable(bob));
    }


    function testBuyOption() public {
        vm.startPrank(alice);
        vm.expectRevert(bytes("wrong price"));
        optionalPurchase.buyOption(0);

        optionalPurchase.buyOption{value: 0.1 ether}(0);
        vm.stopPrank();

        assertEq(optionalPurchase.claimedOffers(0), address(alice));
        assertEq(address(bob).balance, 0.1 ether);
    }

    function testExerciseOption() payable external {
        vm.startPrank(alice);
        optionalPurchase.buyOption{value: 0.1 ether}(0);

        optionalPurchase.exerciseOption{value: 0.8 ether}(0);

        assertEq(optionalPurchase.completedOffers(0), true);
        assertEq(address(bob).balance, 0.9 ether);

        // Transferring the tokens has spent the encumbrance
        assertEq(token.encumbrances(bob, address(optionalPurchase)), 0);
        assertEq(token.balanceOf(alice), 5e18);

        vm.stopPrank();
    }

    function testReleaseOption() external {
        vm.startPrank(alice);
        optionalPurchase.buyOption{value: 0.1 ether}(0);
        assertEq(address(bob).balance, 0.1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(bytes("offer not expired"));
        optionalPurchase.releaseOption(0);

        vm.warp(block.timestamp + 10001);
        optionalPurchase.releaseOption(0);

        // The option expiring unexercised has released the encumbrance!
        assertEq(token.encumbrances(bob, address(optionalPurchase)), uint(0));
        vm.stopPrank();
    }
}
