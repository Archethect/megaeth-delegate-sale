// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract CompleteSaleTest is BaseTest{
    function test_WhenTheFluffyNftIsNotSet(address seller, address buyer, uint256 price) external {
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
        vm.prank(_admin);
        fluffySaleEscrow.completeSale(seller);
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
        vm.prank(_admin);
        fluffySaleEscrow.completeSale(seller);
    }

    function test_WhenTheBuyerHasNoFluffyNFTYet(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        assumePayable(seller);
        assumePayable(buyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _setNFT();

        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.FluffyNFTNotYetMinted.selector));
        vm.prank(_admin);
        fluffySaleEscrow.completeSale(seller);
    }

    function test_WhenTheSaleWasCompletedSuccessfully(address seller, address buyer, uint256 price) external {
        vm.assume(seller != address(0));
        vm.assume(buyer != address(0));
        vm.assume(seller != _feeReceiver);
        assumePayable(seller);
        assumePayable(buyer);
        price = bound(price, 0, 5000000000 ether);

        _createOffer(seller, price);
        vm.deal(buyer, price);
        _buyOffer(seller, buyer, price);
        _setNFT();
        _mintNFT(buyer);

        uint256 sellerBalanceBefore = address(seller).balance;
        uint256 feeReceiverBalanceBefore = address(_feeReceiver).balance;

        vm.prank(_admin);
        fluffySaleEscrow.completeSale(seller);

        // it will mark the offer as successful
        IFluffySaleEscrow.Offer memory offer = fluffySaleEscrow.getOffer(seller);
        assertTrue(offer.success, 'the offer should be marked as successful');
        // it will pay the seller the price minus the fee
        uint256 fee = price * fluffySaleEscrow.feePercentageInBPS() / fluffySaleEscrow.BPS();
        assertEq(address(seller).balance, sellerBalanceBefore + price - fee, 'the seller should be paid the price minus the fee');
        // it will pay the fee to the feeReceiver
        assertEq(address(_feeReceiver).balance, feeReceiverBalanceBefore + fee, 'the seller should be paid the price minus the fee');
    }
}
