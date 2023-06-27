# Encumber

[Encumber](#) is an ERC proposal adding the ability to pledge tokens without giving up ownership of the tokens until the tokens are transferred. This enables use-cases such as non-custodial DeFi, where a protocol has a right to seize tokens (e.g. in liquidation), but otherwise doesn't have custody of the tokens in the interim. This repository includes code snippets on a potential implementation of the Encumber ERC, as well as a few examples of smart contracts which could lever encumbrances.

Feel free to explore and add feedback, comments or new use-cases to this document.

## Encumbrance Token Implementations

### [ERC-20 Encumber Token](./src/encumberableERC20.sol)

The `encumberableERC20` is a proposed implementation of the encumbrance ERC specification. This is a simple ERC-20 token, but it allows a token holder to call `encumber(address taker, uint256 amount)`. Separately, if you've given an allowance to a contract (e.g. a DeFi protocol), that protocol may call `encumberFrom(address owner, address taker, uint256 amount)` to create an encumbrance for itself.

### [ERC-721 adaptation example](./src/encumberableERC721.sol)

A similar example ot the `encumberableERC20`, but exhibited as an ERC-721 token which also follows the Encumber specification as a potential implementation.

## Encumbrance Token Use-Cases

### Toy Options Contract

Contract: [Optional Purchase](./src/optionalPurchase.sol)

A toy options DeFi contract that offers the right to purchase a token for a given time-period. The key interesting fact is that the token is held (in an encumbered state) in the option seller's own wallet until such a time that the option is exercised. If the option expires, then the encumbrance is released and the token never left the owner's own custody.

### EIP-712 Rental

Contract: [Temporary Ownership](./src/temporaryOwnership.sol)

An inversion of the encumbrance-- a toy contract where an NFT is lent to another party but an encumbrance is kept by the lender. That is, the ERC-721 is transfered but there is an encumbrance created from the recipient to the original owner. If the recipient (borrower) doesn't pay "rent" in a timely manner, the ERC-721 reverts ownership back to the original owner. This allows a user to hold the ownership rights to a token by borrowing it, with no risk to the original owner.

## Feedback

Please feel free to add new examples, comment on the specification or implementation code or leave general thoughts as issues. Also, contribute to the [Encumber ERC specification](#) or [its conversation page](#).

All code in the repo is released under a [CC0 license](https://creativecommons.org/share-your-work/public-domain/cc0/).
