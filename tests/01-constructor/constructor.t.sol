// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base.t.sol";
import {FluffySaleEscrow} from "../../src/FluffySaleEscrow.sol";
import {IFluffySaleEscrow} from "../../src/IFluffySaleEscrow.sol";

contract ConstructorTest is BaseTest {
    function test_RevertWhen_AdminIsZero() external {
        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.InvalidAddress.selector));
        new FluffySaleEscrow(address(0), _feeReceiver);
    }

    function test_RevertWhen_FeeReceiverIsZero() external {
        // it should revert
        vm.expectRevert(abi.encodeWithSelector(IFluffySaleEscrow.InvalidAddress.selector));
        new FluffySaleEscrow(_admin, address(0));
    }

    function testFuzz_WhenConstructorParamsAreCorrect(address admin, address feeReceiver) external {
        vm.assume(admin != address(0));
        vm.assume(feeReceiver != address(0));

        FluffySaleEscrow localFluffySaleEscrow = new FluffySaleEscrow(admin, feeReceiver);
        // it should grant the correct roles
        assertEq(localFluffySaleEscrow.hasRole(localFluffySaleEscrow.ADMIN_ROLE(),admin), true, 'admin should have the ADMIN role');
        assertEq(localFluffySaleEscrow.getRoleAdmin(localFluffySaleEscrow.ADMIN_ROLE()), localFluffySaleEscrow.ADMIN_ROLE(), 'admin role should be admin role admin');
        // it should set the feeReceiver
        assertEq(localFluffySaleEscrow.feeReceiver(), feeReceiver, 'feeReceiver should be set correctly');
        // it should set the feePercentage to 10 percent
        assertEq(localFluffySaleEscrow.feePercentageInBPS(), 1000, 'feePercentage should be set to 10 percent');
    }
}
