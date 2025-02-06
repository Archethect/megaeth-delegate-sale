// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from 'forge-std/src/Script.sol';
import {IFluffySaleEscrow} from "../src/IFluffySaleEscrow.sol";
import {FluffySaleEscrow} from "../src/FluffySaleEscrow.sol";
import {MockERC721} from "../src/MockERC721.sol";

contract Deploy is Script {
    function run() external {
        //We use a keystore here
        address deployer = msg.sender;
        vm.startBroadcast(deployer);
       // new FluffySaleEscrow(deployer, deployer);
        new MockERC721();
        vm.stopBroadcast();
    }
}
