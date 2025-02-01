// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FreepadNFT} from "../src/FreepadNFT.sol";

contract FreepadNFTScript is Script {
    FreepadNFT public freepadNFT;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        freepadNFT = new FreepadNFT();

        console.log("FreepadNFT deployed at: ", address(freepadNFT));
        vm.stopBroadcast();
    }
}