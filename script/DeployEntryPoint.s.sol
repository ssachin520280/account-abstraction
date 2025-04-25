// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {EntryPoint} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";

contract DeployEntryPoint is Script {

    address constant BURNER_WALLET = 0x80e71dB45e3F250E060bF991238fc633b52AF39a;

    function run() external returns (EntryPoint) {
        vm.startBroadcast(BURNER_WALLET);

        EntryPoint entryPoint = new EntryPoint();
        console2.log("EntryPoint deployed at:", address(entryPoint));

        vm.stopBroadcast();

        return entryPoint;
    }
}
