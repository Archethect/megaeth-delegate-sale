// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import {IFluffySaleEscrow} from "./IFluffySaleEscrow.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title FluffySaleEscrow
/// @Author Archethect
/// @notice Escrow contract handling the creation, purchase, and finalization of Fluffy NFT whitelist sale offers
contract FluffySaleEscrow is AccessControl, IFluffySaleEscrow {
    /// @notice Role identifier for admin-only functions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @notice Denominator for calculating basis points (BPS)
    uint256 public constant BPS = 10000;

    /// @notice Fee percentage in BPS (default is 1000 → 10%)
    uint256 public feePercentageInBPS;
    /// @notice The receiver of the fee
    address public feeReceiver;
    /// @notice The Fluffy NFT contract implementing IERC721
    IERC721 public fluffyNFT;

    /// @notice Mapping of seller address to their offer
    mapping(address => Offer) public offers;
    /// @notice Tracks if a particular address is currently buying an offer
    mapping(address => bool) public isBuying;

    /**
     * @notice Constructor for FluffySaleEscrow
     * @dev Initializes admin role and sets default fee percentage
     * @param _admin The address with `ADMIN_ROLE` permissions
     * @param _feeReceiver The address to receive fees from sales
     */
    constructor(address _admin, address _feeReceiver) {
        if(_admin == address(0)) revert InvalidAddress();
        if(_feeReceiver == address(0)) revert InvalidAddress();

        _grantRole(ADMIN_ROLE, _admin);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        feeReceiver = _feeReceiver;
        feePercentageInBPS = 1000;
    }

    /**
     * @notice Creates a new offer with a specified price
     * @dev Reverts if the caller is already buying or already has an active offer
     * @param price The asking price (in wei) for this offer
     */
    function createOffer(uint256 price) external {
        if(isBuying[msg.sender]) revert UserIsAlreadyBuying();
        if(offers[msg.sender].seller != address(0)) revert OfferAlreadyExists();
        offers[msg.sender] = Offer({
            seller: msg.sender,
            buyer: address(0),
            price: price,
            success: false
        });
        emit OfferCreated(msg.sender, price);
    }

    /**
     * @notice Reverts an existing offer
     * @dev Reverts if the offer has already been completed or if caller is not the seller
     *      Returns the buyer's funds if a buyer exists
     */
    function revertOffer() external {
        Offer memory offer = offers[msg.sender];
        if(offer.seller != msg.sender) revert NotOwner();
        if(offer.success) revert OfferAlreadyCompleted();
        delete offers[msg.sender];
        if(offer.buyer != address(0)) {
            isBuying[offer.buyer] = false;
            payable(offer.buyer).transfer(offer.price);
        }
        emit OfferReverted(msg.sender);
    }

    /**
     * @notice Allows a buyer to buy an existing offer
     * @dev The buyer must not already be buying and must send the correct payment
     * @param offerId The address of the seller whose offer is being bought
     */
    function buy(address offerId) external payable {
        Offer storage offer = offers[offerId];
        if(isBuying[msg.sender]) revert CanOnlyBuyOnce();
        if(offer.seller == address(0)) revert NonExistingOffer();
        if(offer.buyer != address(0)) revert OfferAlreadyFilled();
        if(msg.value != offer.price) revert IncorrectPayment();
        offer.buyer = msg.sender;
        isBuying[msg.sender] = true;
        emit Bought(offerId, msg.sender);
    }

    /**
     * @notice Reverts a buyer’s purchase
     * @dev Caller must be the buyer, and the NFT must not have been minted yet
     * @param offerId The address of the seller's offer to revert
     */
    function revertBuy(address offerId) external {
        if(address(fluffyNFT) == address(0)) revert FluffyNFTNotSet();
        Offer storage offer = offers[offerId];
        if(offer.buyer != msg.sender) revert NotBuyer();
        if(offer.success) revert OfferAlreadyCompleted();
        if(IERC721(fluffyNFT).balanceOf(offer.buyer) > 0) revert FluffyNFTAlreadyMinted();
        isBuying[offer.buyer] = false;
        address buyer = offer.buyer;
        offer.buyer = address(0);
        (bool success,) = payable(buyer).call{value: offer.price}("");
        if(!success) revert TransferFailed();
        emit BuyReverted(offerId, msg.sender);
    }

    /**
     * @notice Completes a sale, transferring funds to seller and fee to feeReceiver
     * @dev The Fluffy NFT must already be minted to the buyer. Reverts if sale is already completed.
     * @param offerId The address of the seller’s offer to complete
     */
    function completeSale(address offerId) external {
        if(address(fluffyNFT) == address(0)) revert FluffyNFTNotSet();
        Offer storage offer = offers[offerId];
        if(offer.success) revert OfferAlreadyCompleted();
        if(IERC721(fluffyNFT).balanceOf(offer.buyer) == 0) revert FluffyNFTNotYetMinted();
        offer.success = true;
        uint256 fee = offer.price * feePercentageInBPS / BPS;
        (bool success1,) = payable(offer.seller).call{value: offer.price - fee}("");
        (bool success2,) = payable(feeReceiver).call{value: fee}("");
        if(!success1 || !success2) revert TransferFailed();
        emit SaleCompleted(offerId);
    }

    /**
     * @notice Sets the Fluffy NFT contract
     * @dev Restricted to accounts with `ADMIN_ROLE`
     * @param _fluffyNFT The address of the Fluffy NFT contract
     */
    function setFluffyNFT(address _fluffyNFT) external onlyRole(ADMIN_ROLE) {
        if(_fluffyNFT == address(0)) revert InvalidAddress();
        fluffyNFT = IERC721(_fluffyNFT);
    }

    /**
     * @notice Returns the offer struct for a given seller address
     * @param offerId The seller address for which the offer is retrieved
     * @return The Offer struct containing seller, buyer, price, and success status
     */
    function getOffer(address offerId) external view returns (Offer memory) {
        return offers[offerId];
    }
}
