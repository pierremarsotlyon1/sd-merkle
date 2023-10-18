// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/Merkle.sol";
import {Script, console2} from "forge-std/Script.sol";

contract DeploymentScript is Script {
    address public deployer = 0x000755Fbe4A24d7478bfcFC1E561AfCE82d1ff62;
    address public governance = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;

    function run() public {
        vm.broadcast(deployer);
        Merkle merkle = new Merkle(governance);

        if(merkle.owner() != governance) revert("merkle owner not set");
    }
}
