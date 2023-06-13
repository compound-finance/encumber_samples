
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EncumberableERC721.sol";

contract EncumberableErc721Test is Test {
    event Encumber(address indexed owner, address indexed taker, uint tokenId);
    event Release(address indexed owner, address indexed taker, uint tokenId);

    EncumberableERC721 public token;

    address alice = vm.addr(uint256(keccak256('alice')));
    address bob = vm.addr(uint256(keccak256('bob')));
    address charlie = vm.addr(uint256(keccak256('charlie')));

    uint tokenId = uint(1);

    function setUp() public  {
        token = new EncumberableERC721("Test", "eTest");
        token.mint(bob, tokenId);
    }

    function testBlocksBasicTransfer() public {
        // encumber to alice
        vm.startPrank(bob);

        vm.expectEmit(true, true, false, true, address(token));
        emit Encumber(bob, alice, tokenId);

        token.encumber(alice, tokenId);

        // Bob cannot transfer, though he is owner
        vm.expectRevert(bytes("Token is promised to another"));
        token.transferFrom(bob, charlie, tokenId);

        vm.stopPrank();

        assertEq(token.encumbrances(tokenId), alice);

        // alice can transfer, since encumbered to her
        vm.startPrank(alice);
        token.transferFrom(bob, charlie, tokenId);

        assertEq(token.encumbrances(tokenId), address(0));
        vm.stopPrank();
    }

    function testReleasing() public {
        vm.startPrank(bob);
        token.encumber(alice, tokenId);
        vm.stopPrank();
        
        vm.expectEmit(true, true, false, true, address(token));
        emit Release(bob, alice, tokenId);


        vm.startPrank(alice);
        token.release(bob, tokenId);
        vm.stopPrank();

        assertEq(token.encumbrances(tokenId), address(0));
    }
}
