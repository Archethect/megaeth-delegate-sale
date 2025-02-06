# FluffySaleEscrow

A smart contract system that facilitates secure sales of Fluffy NFT whitelists via an escrow mechanism.

## Overview

- **Escrow Contract**: The core `FluffySaleEscrow` contract holds buyers’ Ether in escrow until the NFT is confirmed minted to them.
- **Offer-Centric**: Each seller (address) can create exactly one offer. Buyers can pay to “buy” the offer, with funds held until final completion.
- **Admin Controls**: An admin can set the address of the Fluffy NFT contract and manage certain configuration parameters like fees.

## Purpose

1. **Secure Payment Holding**
  - Ether from a buyer is locked in the contract upon purchase.
  - If the buyer fails or decides not to mint/receive the NFT, the buyer can revert the buy and be refunded.

2. **Easy Offer Lifecycle**
  - Sellers can create an offer with a defined price.
  - Buyers buy the offer by sending the exact payment.
  - The seller can revert the offer if it’s not yet completed.

3. **Fee Mechanism**
  - A configurable fee (in basis points) is deducted from the sale price and sent to a fee receiver upon final sale.
  - The remainder goes to the seller.

4. **Completion upon NFT Mint**
  - The sale is only completed after the buyer actually has the Fluffy NFT.
  - At completion, the contract releases funds to the seller and fee to the fee receiver.

## Key Contracts & Files

- **`IFluffySaleEscrow.sol`**
  - The interface that defines the `Offer` struct, events, errors, and function signatures for the escrow contract.

- **`FluffySaleEscrow.sol`**
  - The main escrow contract that implements the `IFluffySaleEscrow` interface and uses OpenZeppelin’s `AccessControl`.
  - Contains all core logic for creating offers, buying, reverting buys, and completing the sale.

## How It Works

1. **Seller Creates an Offer**
  - Calls `createOffer(price)` to set a price in wei.
  - Stores offer data (seller address, price, `success = false`).

2. **Buyer Purchases the Offer**
  - Calls `buy(offerId)` and sends `msg.value` equal to the offer’s price.
  - The Ether is held in escrow.

3. **Revert Purchase (Buyer)**
  - If the buyer has not minted/received the Fluffy NFT, they can revert.
  - Ether is refunded to the buyer, and the offer is reopened for new buyers.

4. **Complete the Sale**
  - Once the buyer has the Fluffy NFT (verified on-chain via `IERC721.balanceOf`), anyone can call `completeSale(offerId)`.
  - The contract pays out the sale amount minus fee to the seller and sends the fee portion to the feeReceiver.
  - The offer’s `success` status is updated, preventing further modifications.

## Roles & Permissions

- **`ADMIN_ROLE`**
  - Granted to a designated address in the constructor.
  - Can call `setFluffyNFT(_fluffyNFT)` to configure the NFT contract address.
  - Controls certain aspects like fee updates in future versions (not shown in this minimal example).

## Error Handling

The contract reverts with custom errors when something unexpected or disallowed occurs, such as:

- **`InvalidAddress`**: Thrown when zero address is provided for an admin, fee receiver, or NFT contract.
- **`UserIsAlreadyBuying`**: Thrown if a user attempts to create an offer while already buying.
- **`OfferAlreadyExists`** / **`NonExistingOffer`**: Thrown when trying to create or buy a non-existent or repeated offer.
- **...** (See full list in the code for more details).

## Events

- **`OfferCreated`**: Emitted when a seller creates a new offer.
- **`OfferReverted`**: Emitted when a seller cancels their offer.
- **`Bought`**: Emitted when a buyer pays into an offer.
- **`BuyReverted`**: Emitted when a buyer reverts their purchase.
- **`SaleCompleted`**: Emitted when the sale is finalized and funds are disbursed.

## Local Development

1. **Clone** the repo and navigate to it.
2. **Install** dependencies (e.g., Hardhat, Foundry, or other tool of your choice).
3. **Compile** the contracts using your preferred development environment.
4. **Deploy** the `FluffySaleEscrow` contract to a local or test network.
5. **Test** the functions by creating offers, buying, reverting, and finalizing.

## Contributing

1. Fork the repository.
2. Create a new feature branch.
3. Submit a pull request describing your changes.

## License

This project is licensed under the [MIT License](LICENSE).
