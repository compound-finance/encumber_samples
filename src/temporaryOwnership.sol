
// A token can be sent to another user with an encumberance back to the original owner to be released based on immutable smart contract logic.
// This would allow the leasing of an NFT for the duration of an event, or to allow a payment plan for purchasing an NFT that reverts back to the
// original owner if payments are not met. 

// This requires transferring the token to the recipient while retaining an encumbrance to back to a logic contract.

pragma solidity ^0.8.0;

import { EncumberableERC721 } from './EncumberableERC721.sol';

contract TemporaryOwnership {
    // tokenContract -> tokenId -> expiration
    mapping (address => mapping (uint256 => address)) public expirations;

    function lendNft(tokenContract, tokenId, recipient, expiration) public  {
        EncumberableERC721(tokenContract).transferFromWithEncumbrance(msg.sender, recipient, address(this), tokenId);
        expirations[tokenContract][tokenId] = expiration;
    }

    function recallNft(address tokenContract, uint tokenId, address holder) public {
        uint expiration = expirations[tokenContract][tokenId];
        require(expiration != 0, "token not lent");
        require(block.timestamp > expiration, "Term not complete");
        EncumberableERC721(tokenContract).transferFrom(holder, msg.sender, tokenId);
        delete expirations[tokenContract][tokenId];
    }

    function letRecipientKeepNft(address tokenContract, uint tokenId, address holder) public {
        EncumberableERC721(tokenContract).release(holder, address(this), tokenId);
        delete expirations[tokenContract][tokenId];
    }
}
