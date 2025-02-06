// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract RevertBuyTest is BaseTest {
    function testFuzz_WhenTheFluffyNftIsNotSet(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.FluffyNFTNotSet.selector));
        vm.prank(buyer);
        fluffySaleEscrow.revertBuy(seller);
    }

    function test_WhenTheSenderIsNotTheBuyer(address seller, address buyer, address spoofBuyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        vm.assume(spoofBuyer != address(0));
        vm.assume(buyer != spoofBuyer);
        assumePayable(seller);
        assumePayable(buyer);
        assumePayable(spoofBuyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _setNFT();

        // it should revert
        vm.deal(spoofBuyer, price);
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.NotBuyer.selector));
        vm.prank(spoofBuyer);
        fluffySaleEscrow.revertBuy(seller);
    }

    function test_WhenTheOfferWasAlreadyHandledSuccessfully(address seller, address buyer, uint256 price) external {
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
        vm.prank(buyer);
        fluffySaleEscrow.revertBuy(seller);
    }

    function test_WhenTheBuyerHasAFluffyNFTAlready(address seller, address buyer, uint256 price) external {
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

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.FluffyNFTAlreadyMinted.selector));
        vm.prank(buyer);
        fluffySaleEscrow.revertBuy(seller);
    }

    function test_WhenTheBuyWasRevertedSuccessfully(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _setNFT();

        uint256 buyerBalanceBefore = address(buyer).balance;

        vm.prank(buyer);
        fluffySaleEscrow.revertBuy(seller);

        // it will mark the buyer as not buying
        assertFalse(fluffySaleEscrow.isBuying(buyer), 'buyer should not be marked as a buyer');
        // it marks the buyer as a buyer
        // it will set the buyer of the offer to 0
        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        assertEq(offer.buyer, address(0), 'buyer should be set to zero address');
        // it will refund the buyer
        assertEq(address(buyer).balance, buyerBalanceBefore + price, 'buyer should have been refunded');
    }
}
