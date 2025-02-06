// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PRBTest} from "@prb/test/PRBTest.sol";

import {StdCheats, StdCheatsSafe} from "forge-std/src/StdCheats.sol";
import {StdUtils} from "forge-std/src/StdUtils.sol";
import {FluffySaleEscrow} from "../src/FluffySaleEscrow.sol";
import {MockERC721} from "../src/MockERC721.sol";

contract BaseTest is PRBTest, StdCheats, StdUtils {
    FluffySaleEscrow internal fluffySaleEscrow;
    MockERC721 internal mockERC721;

    address internal _admin = makeAddr('admin');
    address internal _feeReceiver = makeAddr('feeReceiver');

    function setUp() public virtual {
        fluffySaleEscrow = new FluffySaleEscrow(_admin, _feeReceiver);
        mockERC721 = new MockERC721();
    }

    function _createOffer(address seller, uint256 price) internal {
        vm.prank(seller);
        fluffySaleEscrow.createOffer(price);
    }

    function _buyOffer(address seller, address buyer, uint256 price) internal {
        vm.prank(buyer);
        fluffySaleEscrow.buy{value: price}(seller);
    }

    function _setNFT() internal {
        vm.prank(_admin);
        fluffySaleEscrow.setFluffyNFT(address(mockERC721));
    }

    function _mintNFT(address receiver) internal {
        vm.prank(receiver);
        mockERC721.mint(receiver);
    }

    function _completeSale(address seller) internal {
        vm.prank(_admin);
        fluffySaleEscrow.completeSale(seller);
    }
}
