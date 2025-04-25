// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {PackedUserOperation} from  "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    address constant SEPOLIA_USDC = 0xf08A50178dfcDe18524640EA6618a1f965821715;
    address constant MINIMAL_ACCOUNT = 0x6d980aaE2072fc158E8A235f8B93754320d35117;
    address constant BURNER_WALLET = 0x80e71dB45e3F250E060bF991238fc633b52AF39a;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        address dest = SEPOLIA_USDC;
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, BURNER_WALLET, 1e18);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory userOp = generateSignedUserOperation(executeCallData, helperConfig.getConfig(), MINIMAL_ACCOUNT);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast(BURNER_WALLET);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(helperConfig.getConfig().account));
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config, address minimalAccount) public returns (PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        console2.log(nonce);

        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        console2.log("40");

        // 2. Get the userOp hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        console2.log("44");
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        console2.log("46");

        // 3. Sign it, and return it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce) internal pure returns (PackedUserOperation memory) {
        uint256 verificationGasLimit = 16777216;
        uint256 callGasLimit = verificationGasLimit;
        uint256 maxPriorityFeePerGas = 256;
        uint256 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}