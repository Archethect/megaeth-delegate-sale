// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract RevertOfferTest is BaseTest {
    function testFuzz_RevertWhen_TheSenderIsNotTheSellOfferCreator(address seller, address spoofSeller, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(spoofSeller != address(0));
        vm.assume(spoofSeller != seller);
        assumePayable(seller);
        assumePayable(spoofSeller);

        _createOffer(seller, price);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.NotOwner.selector));
        vm.prank(spoofSeller);
        fluffySaleEscrow.revertOffer();
    }

    function testFuzz_RevertWhen_TheOfferAlreadyWasHandledSuccesfully(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _setNFT();
        _mintNFT(buyer);
        _completeSale(seller);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.OfferAlreadyCompleted.selector));
        vm.prank(seller);
        fluffySaleEscrow.revertOffer();
    }

    modifier whenTheSenderCanRevertTheOffer(address seller, address buyer, uint256 price, bool needsBuyer) {
        vm.assume(seller != address(0));
        vm.assume(seller != buyer);
        assumePayable(seller);
        assumeNotPrecompile(seller);
        price = bound(price, 0, 5000000000 ether);

        if(needsBuyer) {
            vm.assume(buyer != address(0));
            assumePayable(buyer);
            assumeNotPrecompile(buyer);
            vm.assume(seller != buyer);
        }

        _createOffer(seller, price);
        _;
    }

    modifier givenThereIsABuyer(address seller, address buyer) {
        uint256 price = fluffySaleEscrow.getOffer(seller).price;
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _;
    }

    function test_RevertWhen_TheBuyerHasAlreadyMinted(address seller, address buyer, uint256 price) external whenTheSenderCanRevertTheOffer(seller, buyer, price, true) givenThereIsABuyer(seller, buyer) {
        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        price = offer.price;
        buyer = offer.buyer;
        _setNFT();
        _mintNFT(buyer);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.FluffyNFTAlreadyMinted.selector));
        vm.prank(seller);
        fluffySaleEscrow.revertOffer();
    }

    function test_WhenTheBuyerHasNotMinted(address seller, address buyer, uint256 price) external whenTheSenderCanRevertTheOffer(seller, buyer, price, true) givenThereIsABuyer(seller, buyer) {

        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        price = offer.price;

        assertEq(address(fluffySaleEscrow).balance, price, 'the contract balance should be equal to the price');
        uint256 buyerBalanceBefore = address(buyer).balance;

        assertEq(offer.seller, seller, 'seller should be set correctly');
        assertEq(offer.buyer, buyer, 'buyer should be set correctly');
        assertEq(offer.price, price, 'price should be set correctly');
        assertEq(offer.success, false, 'success should be set to false');

        vm.prank(seller);
        fluffySaleEscrow.revertOffer();
        // it deletes the offer
        offer = fluffySaleEscrow.getOffer(seller);
        assertEq(offer.seller, address(0), 'seller should be set correctly');
        assertEq(offer.buyer, address(0), 'buyer should be set correctly');
        assertEq(offer.price, 0, 'price should be set correctly');
        assertEq(offer.success, false, 'success should be set to false');
        // it refunds the buyer
        assertEq(address(fluffySaleEscrow).balance, 0, 'the contract balance should be zero');
        assertEq(address(buyer).balance, buyerBalanceBefore + price, 'the buyer balance should be equal to the price');
    }

    function test_GivenThereIsNoBuyer(address seller, uint256 price) external whenTheSenderCanRevertTheOffer(seller, address(0), price, false) {
        price = fluffySaleEscrow.getOffer(seller).price;

        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        assertEq(offer.seller, seller, 'seller should be set correctly');
        assertEq(offer.buyer, address(0), 'buyer should be set correctly');
        assertEq(offer.price, price, 'price should be set correctly');
        assertEq(offer.success, false, 'success should be set to false');

        vm.prank(seller);
        fluffySaleEscrow.revertOffer();
        // it deletes the offer
        offer = fluffySaleEscrow.getOffer(seller);
        assertEq(offer.seller, address(0), 'seller should be set correctly');
        assertEq(offer.buyer, address(0), 'buyer should be set correctly');
        assertEq(offer.price, 0, 'price should be set correctly');
        assertEq(offer.success, false, 'success should be set to false');
    }
}

