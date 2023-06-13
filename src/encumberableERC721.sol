// An erc-721 token that implements the encumber interface by blocking transfers.

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract EncumberableERC721 is ERC721 {
  // token ID -> taker
  mapping (uint256 => address) public encumbrances;

  address public minter;

  event Encumber(address indexed owner, address indexed taker, uint encumberedTokenId);
  event Release(address indexed owner, address indexed taker, uint releasedTokenId);

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    minter = msg.sender;
  }

  function mint(address to, uint256 tokenId) public {
    require(msg.sender == minter, "only minter");
    _mint(to, tokenId);
  }

  function encumber(address taker, uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Not token owner");
    _encumber(msg.sender, taker, tokenId);
  }

  function encumberFrom(address owner, address taker, uint256 tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved address for token");
    _encumber(owner, taker, tokenId);
  }

  function _encumber(address owner, address taker, uint256 tokenId) public {
    require(encumbrances[tokenId] == address(0), "Token is promised to another");
    encumbrances[tokenId] = taker;
    emit Encumber(owner, taker, tokenId);
  }

  function release(address owner, uint256 tokenId) public {
    require(msg.sender == encumbrances[tokenId], "Not encumbrance taker");
    delete encumbrances[tokenId];
    emit Release(owner, msg.sender, tokenId);
  }

  function transferFrom(address from, address to, uint tokenId) public override {
      address taker = encumbrances[tokenId];

      if ( taker == msg.sender ) {
          // force the approval if encumbered
          _approve(msg.sender, tokenId);
          // and delete the encumbrance
          delete encumbrances[tokenId];
      } else {
          require(taker == address(0), "Token is promised to another");
      }

      super.transferFrom(from, to, tokenId);
  }

  function transferWithEncumbrance(address to, address taker, uint256 tokenId) public {
    _transfer(msg.sender, to, tokenId);
    _encumber(to, taker, tokenId);
  }

  function transferFromWithEncumbrance(address from, address to, address taker, uint256 tokenId) public {
    _transfer(from, to, tokenId);
    _encumber(to, taker, tokenId);
  }
}
