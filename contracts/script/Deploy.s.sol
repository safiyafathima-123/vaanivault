// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {VaaniLicence} from "../src/VaaniLicence.sol";
import {VaaniVault} from "../src/VaaniVault.sol";

contract Deploy is Script {
    function run() external returns (VaaniLicence licence, VaaniVault vault) {
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast();

        address deployer = msg.sender;

        // 1. Deploy VaaniLicence with deployer as admin
        licence = new VaaniLicence(deployer);

        // 2. Deploy VaaniVault with deployer as admin and licence, treasury, relayer
        vault = new VaaniVault(deployer, address(licence), treasury, relayer);

        // 3. Connect licence to vault
        licence.setVault(address(vault));

        vm.stopBroadcast();

        console2.log("=== Deployment Summary ===");
        console2.log("Deployer / Admin:", deployer);
        console2.log("VaaniLicence deployed to:", address(licence));
        console2.log("VaaniVault deployed to:", address(vault));
        console2.log("Platform Treasury:", treasury);
        console2.log("Relayer:", relayer);
        console2.log("Deployment Block Number:", block.number);
    }
}
