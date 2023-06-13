
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EncumberableERC721.sol";
import "../src/TemporaryOwnership.sol";

contract TemporaryOwnershipTest is Test {
    event Encumber(address indexed owner, address indexed taker, uint encumberedAmount);
    event Release(address indexed owner, address indexed taker, uint releasedAmount);

    EncumberableERC721 public token;
    TemporaryOwnership public temporaryOwnership;

    address alice = vm.addr(uint256(keccak256('alice')));
    address bob = vm.addr(uint256(keccak256('bob')));
    address charlie = vm.addr(uint256(keccak256('charlie')));
    uint tokenId = uint(1);

    function setUp() public  {
        token = new EncumberableERC721("Test", "eTest");
        token.mint(bob, tokenId);

        temporaryOwnership = new TemporaryOwnership();
    }

    function testLendNft() public {
        _bobLendToAlice();
        assertEq(token.encumbrances(alice, tokenId), address(temporaryOwnership));
        assertEq(token.ownerOf(tokenId), alice);
    }

    function testRecallNft() payable external {
        _bobLendToAlice();

        vm.startPrank(bob);

        vm.expectRevert(bytes("Term not complete"));
        temporaryOwnership.recallNft(address(token), tokenId, alice);

        vm.warp(block.timestamp + 10001);

        console.log(bob);
        console.log(address( temporaryOwnership ));
        console.log(token.encumbrances(alice, tokenId));

        temporaryOwnership.recallNft(address(token), tokenId, alice);
        vm.stopPrank();

        assertEq(token.encumbrances(alice, tokenId), address(0));
        assertEq(token.ownerOf(tokenId), bob);
    }

    function testLetRecipientKeepNft() external {
        _bobLendToAlice();

        vm.startPrank(bob);
        temporaryOwnership.letRecipientKeepNft(address(token), tokenId, alice);
        vm.stopPrank();

        assertEq(token.encumbrances(alice, tokenId), address(0));
        assertEq(token.ownerOf(tokenId), alice);
    }

    function _bobLendToAlice() internal {
        vm.startPrank(bob);
        token.approve(address(temporaryOwnership), tokenId);
        temporaryOwnership.lendNft(address(token), tokenId, address(alice), block.timestamp + 1000);

        vm.stopPrank();
    }
}
