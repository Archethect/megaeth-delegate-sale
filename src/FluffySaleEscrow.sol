// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import {IFluffySaleEscrow} from "./IFluffySaleEscrow.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FluffySaleEscrow is AccessControl, IFluffySaleEscrow {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant BPS = 10000;

    uint256 public feePercentageInBPS;
    address public feeReceiver;
    IERC721 public fluffyNFT;

    mapping(address => Offer) public offers;
    mapping(address => bool) public isBuying;

    constructor(address _admin, address _feeReceiver) {
        if(_admin == address(0)) revert InvalidAddress();
        if(_feeReceiver == address(0)) revert InvalidAddress();

        _grantRole(ADMIN_ROLE, _admin);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        feeReceiver = _feeReceiver;
        feePercentageInBPS = 1000;
    }

    function createOffer(uint256 price) external {
        if(offers[msg.sender].seller != address(0)) revert OfferAlreadyExists();
        offers[msg.sender] = Offer({
            seller: msg.sender,
            buyer: address(0),
            price: price,
            success: false
        });
        emit OfferCreated(msg.sender, price);
    }

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

    function revertBuy(address offerId) external {
        if(address(fluffyNFT) == address(0)) revert FluffyNFTNotSet();
        Offer storage offer = offers[offerId];
        if(offer.buyer != msg.sender) revert NotBuyer();
        if(offer.success) revert OfferAlreadyCompleted();
        if(IERC721(fluffyNFT).balanceOf(offer.buyer) > 0) revert FluffyNFTAlreadyMinted();
        isBuying[offer.buyer] = false;
        offer.buyer = address(0);
        (bool success,) = payable(offer.buyer).call{value: offer.price}("");
        if(!success) revert TransferFailed();
        emit BuyReverted(offerId, msg.sender);
    }



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

    function setFluffyNFT(address _fluffyNFT) external onlyRole(ADMIN_ROLE) {
        if(_fluffyNFT == address(0)) revert InvalidAddress();
        fluffyNFT = IERC721(_fluffyNFT);
    }

    function getOffer(address offerId) external view returns (Offer memory) {
        return offers[offerId];
    }
}
