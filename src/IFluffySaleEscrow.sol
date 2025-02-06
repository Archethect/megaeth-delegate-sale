// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

/**
 * @title IFluffySaleEscrow
 * @Author Archethect
 * @notice Interface for the FluffySaleEscrow contract
 */
interface IFluffySaleEscrow {
    /**
     * @notice Structure containing information about a sale offer
     * @param seller The address of the user listing the offer
     * @param buyer The address of the buyer who purchases the offer
     * @param price The price (in wei) of the offer
     * @param success Indicates whether the sale has been successfully completed
     */
    struct Offer {
        address seller;
        address buyer;
        uint256 price;
        bool success;
    }

    // ----------------------  Custom Errors  ----------------------

    /// @notice Thrown when an address is zero or invalid
    error InvalidAddress();

    /// @notice Thrown when a user tries to buy while already buying another offer
    error UserIsAlreadyBuying();

    /// @notice Thrown when an offer is created by a user who already has an active offer
    error OfferAlreadyExists();

    /// @notice Thrown when a non-owner tries to modify or revert an offer
    error NotOwner();

    /// @notice Thrown when an action is attempted on an offer that was already completed
    error OfferAlreadyCompleted();

    /// @notice Thrown when a user tries to buy while already holding another buy position
    error CanOnlyBuyOnce();

    /// @notice Thrown when an action is attempted on an offer that does not exist
    error NonExistingOffer();

    /// @notice Thrown when trying to buy an offer that is already filled by another buyer
    error OfferAlreadyFilled();

    /// @notice Thrown when the amount of ether sent does not match the required offer price
    error IncorrectPayment();

    /// @notice Thrown when the NFT address has not been set in the contract
    error FluffyNFTNotSet();

    /// @notice Thrown when a non-buyer attempts a buyer-only action
    error NotBuyer();

    /// @notice Thrown when the buyer already owns the Fluffy NFT (minted) and tries to revert
    error FluffyNFTAlreadyMinted();

    /// @notice Thrown when a transfer of ether fails
    error TransferFailed();

    /// @notice Thrown when a sale completion is attempted but the buyer has not yet minted/received the NFT
    error FluffyNFTNotYetMinted();

    // ----------------------  Events  ----------------------

    /**
     * @notice Emitted when a new offer is created
     * @param seller The address of the user who created the offer
     * @param price The price (in wei) set for the offer
     */
    event OfferCreated(address indexed seller, uint256 price);

    /**
     * @notice Emitted when an offer is reverted by the seller
     * @param seller The address of the seller who reverted the offer
     */
    event OfferReverted(address indexed seller);

    /**
     * @notice Emitted when a buyer buys into an existing offer
     * @param offerId The address of the seller’s offer
     * @param buyer The address of the buyer
     */
    event Bought(address indexed offerId, address indexed buyer);

    /**
     * @notice Emitted when a buyer reverts their buy
     * @param offerId The address of the seller’s offer
     * @param buyer The address of the buyer who reverted the purchase
     */
    event BuyReverted(address indexed offerId, address indexed buyer);

    /**
     * @notice Emitted when a sale is successfully completed
     * @param offerId The address of the seller’s offer
     */
    event SaleCompleted(address indexed offerId);

    // ----------------------  Functions  ----------------------

    /**
     * @notice Creates a new offer
     * @dev An offer cannot be created if the user is already buying or if one already exists for them
     * @param price The asking price (in wei) for the offer
     */
    function createOffer(uint256 price) external;

    /**
     * @notice Reverts an existing offer
     * @dev Only the owner of the offer can revert it
     *      If the offer had a buyer, that buyer’s funds are returned
     */
    function revertOffer() external;

    /**
     * @notice Allows a buyer to buy an existing offer
     * @dev The buyer must send the exact payment (in wei)
     *      A buyer can only buy once at a time
     * @param offerId The address of the seller's offer to buy
     */
    function buy(address offerId) external payable;

    /**
     * @notice Allows the buyer to revert their buy
     * @dev Only valid if the NFT has not been minted/transferred to the buyer
     * @param offerId The address of the seller's offer
     */
    function revertBuy(address offerId) external;

    /**
     * @notice Completes the sale if the buyer has minted/received the Fluffy NFT
     * @dev Distributes the payment minus fees to the seller, and the fee to the fee receiver
     * @param offerId The address of the seller's offer
     */
    function completeSale(address offerId) external;

    /**
     * @notice Sets the Fluffy NFT contract address (for checking ownership)
     * @dev Can only be called by an admin
     * @param _fluffyNFT The address of the Fluffy NFT contract
     */
    function setFluffyNFT(address _fluffyNFT) external;

    /**
     * @notice Retrieves an existing offer by seller address
     * @param offerId The address of the seller
     * @return An `Offer` struct containing all offer details
     */
    function getOffer(address offerId) external view returns (Offer memory);
}
