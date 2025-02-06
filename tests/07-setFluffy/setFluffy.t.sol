// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract SetFluffyTest is BaseTest {
    function testFuzz_WhenTheSenderIsNotAnAdmin(address setter, address nft) external {
        vm.assume(setter != _admin);
        // it will revert
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector,setter,fluffySaleEscrow.ADMIN_ROLE()));
        vm.prank(setter);
        fluffySaleEscrow.setFluffyNFT(nft);
    }

    function test_WhenTheAddressIs0() external {
        // it will revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.InvalidAddress.selector));
        vm.prank(_admin);
        fluffySaleEscrow.setFluffyNFT(address(0));
    }

    function testFuzz_WhenTheSettingWasSuccessful(address nft) external {
        // it updates the fluffy address
        vm.assume(nft != address(0));

        vm.prank(_admin);
        fluffySaleEscrow.setFluffyNFT(nft);

        assertEq(address(fluffySaleEscrow.fluffyNFT()), nft, 'fluffyNFT should be set correctly');
    }
}
