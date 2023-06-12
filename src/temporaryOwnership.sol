
// A token can be sent to another user with an encumberance back to the original owner to be released based on immutable smart contract logic.
// This would allow the leasing of an NFT for the duration of an event, or to allow a payment plan for purchasing an NFT that reverts back to the
// original owner if payments are not met. 

// This requires transferring the token to the recipient while retaining an encumbrance to back to a logic contract.

pragma solidity ^0.8.0;

import { EncumberableERC721 } from './EncumberableERC721.sol';

contract TemporaryOwnership {
    struct Receipt {
        address originalOwner;
        uint expiration;
    }
    // tokenContract -> tokenId -> expiration
    mapping (address => mapping (uint256 => Receipt)) public receipts;

    function lendNft(address tokenContract, uint tokenId, address recipient, uint expiration) external  {
        EncumberableERC721(tokenContract).transferFromWithEncumbrance(msg.sender, recipient, address(this), tokenId);
        receipts[tokenContract][tokenId] = Receipt(msg.sender, expiration);
    }

    function recallNft(address tokenContract, uint tokenId, address holder) external {
        Receipt memory receipt = receipts[tokenContract][tokenId];
        require(receipt.expiration != 0, "token not lent");
        require(block.timestamp > receipt.expiration, "Term not complete");
        require(receipt.originalOwner == msg.sender);

        EncumberableERC721(tokenContract).transferFrom(holder, msg.sender, tokenId);
        delete receipts[tokenContract][tokenId];
    }

    function letRecipientKeepNft(address tokenContract, uint tokenId, address holder) external {
        Receipt memory receipt = receipts[tokenContract][tokenId];
        require(receipt.originalOwner == msg.sender);

        EncumberableERC721(tokenContract).release(holder, tokenId);
        delete receipts[tokenContract][tokenId];
    }
}
