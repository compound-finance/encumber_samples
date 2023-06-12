// A token can be encumbered to an option purchase contract. Then, another account can purchase the right to buy the tokens at a given price. 

pragma solidity ^0.8.0;

import { EncumberableERC20 } from './EncumberableERC20.sol';

contract OptionalPurchase {
    struct Offer {
        address token;
        uint holdPrice;
        uint purchasePrice;
        uint expiration;
        address writer;
    }

    uint public offerCount;
    mapping (uint => Offer) public offersById;
    mapping (uint => claimer) public claimedOffers;
    mapping (uint => bool) public completedOffers;

    function offerOption(address tokenContract, uint holdPrice, uint purchasePrice, uint expiration) public {
        uint size = EncumberableERC20(tokenContract).encumbrances(msg.sender, address(this)); 
        uint id = offerCount;
        offersById[id] = Offer(tokenContract, holdPrice, purchasePrice, size, expiration, msg.sender);
        offerCount++;
    }

    function buyOption(uint id) payable {
        Offer memory offer = offersById[id];
        require(offer.writer != address(O), "does not exist");
        require(msg.value == offer.holdPrice, "Wrong price");
        require(claimedOffers[id] == address(O), "already claimed");
        offer.writer.transfer(msg.value);
        claimedOffers[id] = msg.sender;
    }

    function exerciseOption(uint id) payable {
        Offer memory offer = offersById[id];
        require(claimedOffers[id] = msg.sender, "not your option");
        require(completedOffers[id] == false, "offer is completed");
        require(msg.value == offer.purchasePrice, "Wrong price");

        offer.writer.transfer(msg.value);
        EncumberableERC20(offer.token).transferFrom(offer.writer, msg.sender, offer.size);
        completedOffers[id] = true;
    }

    function releaseOption(uint id) {
        Offer memory offer = offersById[id];
        require(offer.writer == msg.sender, "not your option");
        require(offer.expiration > block.timestamp, "offer not expired");
        EncumberableERC20(offer.token).release(offer.writer, offer.size);

        completedOffers[id] = true;
    }
}
