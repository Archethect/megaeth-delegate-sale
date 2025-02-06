// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract CreateOfferTest is BaseTest {
    function testFuzz_RevertWhen_TheSellerIsAlreadyBuying(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.UserIsAlreadyBuying.selector));
        vm.prank(buyer);
        fluffySaleEscrow.createOffer(price);
    }

    function testFuzz_RevertWhen_TheSellerTriesToSellASecondTime(address seller, uint256 price) external {
        vm.assume(seller != address(0));
        assumePayable(seller);

        _createOffer(seller, price);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.OfferAlreadyExists.selector));
        vm.prank(seller);
        fluffySaleEscrow.createOffer(price);
    }

    function testFuzz_WhenTheSellerIsAllowedToSell(address seller, uint256 price) external {
        vm.assume(seller != address(0));
        assumePayable(seller);

        // it creates an offer
        vm.prank(seller);
        vm.expectEmit();
        emit IFluffySaleEscrow.OfferCreated(seller, price);
        fluffySaleEscrow.createOffer(price);

        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);

        assertEq(offer.seller, seller, 'seller should be set correctly');
        assertEq(offer.buyer, address(0), 'buyer should be set to zero address');
        assertEq(offer.price, price, 'price should be set correctly');
        assertEq(offer.success, false, 'success should be set to false');
    }
}
