// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract BuyTest is BaseTest {
    function testFuzz_RevertWhen_TheBuyerIsAlreadyABuyer(address seller1, address seller2, address buyer, uint256 price) external {
        vm.assume(seller1 != address(0));
        vm.assume(seller1 != seller2);
        vm.assume(buyer != address(0));
        assumePayable(seller1);
        assumePayable(seller2);
        assumePayable(buyer);

        _createOffer(seller1, price);
        _createOffer(seller2, price);
        vm.deal(buyer, price);
        _buyOffer(seller1, buyer, price);

        // it should revert
        vm.deal(buyer, price);
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.CanOnlyBuyOnce.selector));
        vm.prank(buyer);
        fluffySaleEscrow.buy(seller2);
    }

    function testFuzz_RevertWhen_TheBuyerHasAlreadyMinted(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);

        _createOffer(seller, price);
        _setNFT();
        _mintNFT(buyer);

        // it should revert
        vm.deal(buyer, price);
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.FluffyNFTAlreadyMinted.selector));
        vm.prank(buyer);
        fluffySaleEscrow.buy(seller);
    }

    function testFuzz_RevertWhen_TheOfferDoesNotExist(address buyer, address offerId) external {
        vm.assume(buyer != address(0));
        assumePayable(buyer);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.NonExistingOffer.selector));
        vm.prank(buyer);
        fluffySaleEscrow.buy(offerId);
    }

    function testFuzz_RevertWhen_ThereIsAlreadyABuyerForTheOffer(address seller, address buyer1, address buyer2, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer1 != address(0));
        vm.assume(buyer2 != address(0));
        vm.assume(buyer1 != buyer2);
        vm.assume(seller != buyer1);
        vm.assume(seller != buyer2);
        assumePayable(buyer1);
        assumePayable(buyer2);
        assumePayable(seller);

        _createOffer(seller, price);
        vm.deal(buyer1, price);
        _buyOffer(seller, buyer1, price);

        // it should revert
        vm.deal(buyer2, price);
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.OfferAlreadyFilled.selector));
        vm.prank(buyer2);
        fluffySaleEscrow.buy(seller);
    }

    function testFuzz_RevertWhen_ThePaidValueIsNotTheSameAsThePrice(address seller, address buyer, uint256 price, uint256 paying) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);
        vm.assume(price != paying);

        _createOffer(seller, price);

        // it should revert
        vm.deal(buyer, paying);
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.IncorrectPayment.selector));
        vm.prank(buyer);
        fluffySaleEscrow.buy{value: paying}(seller);
    }

    function testFuzz_WhenTheBuyerCanBuy(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);

        _createOffer(seller, price);

        // it should revert
        vm.deal(buyer, price);
        vm.prank(buyer);
        fluffySaleEscrow.buy{value: price}(seller);

        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        // it marks the offer as bought
        assertEq(offer.buyer, buyer, 'buyer should be set correctly');
        // it marks the buyer as a buyer
        assertTrue(fluffySaleEscrow.isBuying(buyer), 'buyer should be marked as a buyer');
    }
}
