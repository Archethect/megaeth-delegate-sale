// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

interface IFluffySaleEscrow {

    struct Offer {
        address seller;
        address buyer;
        uint256 price;
        bool success;
    }

    error InvalidAddress();
    error OfferAlreadyExists();
    error NotOwner();
    error OfferAlreadyCompleted();
    error NonExistingOffer();
    error OfferAlreadyFilled();
    error IncorrectPayment();
    error FluffyNFTNotSet();
    error NotBuyer();
    error FluffyNFTAlreadyMinted();
    error TransferFailed();
    error FluffyNFTNotYetMinted();
    error CanOnlyBuyOnce();
    error UserIsAlreadyBuying();


    event OfferCreated(address indexed seller, uint256 price);
    event OfferReverted(address indexed seller);
    event Bought(address indexed offerId, address indexed buyer);
    event BuyReverted(address indexed offerId, address indexed buyer);
    event SaleCompleted(address indexed offerId);

    function createOffer(uint256 price) external;
    function revertOffer() external;
    function buy(address offerId) external payable;
    function revertBuy(address offerId) external;
    function completeSale(address offerId) external;
    function setFluffyNFT(address _fluffyNFT) external;
    function getOffer(address offerId) external view returns (Offer memory);
    function isBuying(address buyer) external view returns (bool);
}
