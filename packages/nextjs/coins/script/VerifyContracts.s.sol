// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";

/// @title VerifyContracts
/// @notice Script to verify deployed contracts on BaseScan
contract VerifyContracts is Script {
    
    // Base Sepolia addresses from deployment
    address constant FACTORY_PROXY = 0xAe028301c7822F2c254A43451D22dB5Fe447a4a0;
    address constant FACTORY_IMPL = 0xb4ac7Bac55f22B88C43b848f3D6d1492C4C823f1;
    
    // Constructor arguments for ZoraFactoryImpl
    address constant COIN_V4_IMPL = 0x37f77Ad8b997B0b927DA4233C9607Cf55EDc29Fd;
    address constant CREATOR_COIN_IMPL = 0x08928FB15DE474f89BaE21DC50b8758Cb882D5EE;
    address constant HOOK = 0xe0eC17Ab9f7ce52cC60DFB64E0A0A705d02Bd040;
    address constant ZORA_HOOK_REGISTRY = 0x0000000000000000000000000000000000000000;
    
    function run() external view {
        console2.log("=== CONTRACT VERIFICATION COMMANDS ===");
        console2.log("Use these commands to verify your contracts on BaseScan:\n");
        
        // 1. Factory Implementation verification
        console2.log("1. VERIFY FACTORY IMPLEMENTATION:");
        console2.log("Contract: ZoraFactoryImpl");
        console2.log("Address:", FACTORY_IMPL);
        console2.log("Constructor args:");
        console2.log("  coinV4Impl:", COIN_V4_IMPL);
        console2.log("  creatorCoinImpl:", CREATOR_COIN_IMPL);
        console2.log("  hook:", HOOK);
        console2.log("  zoraHookRegistry:", ZORA_HOOK_REGISTRY);
        
        // Generate encoded constructor arguments
        bytes memory constructorArgs = abi.encode(
            COIN_V4_IMPL,
            CREATOR_COIN_IMPL,
            HOOK,
            ZORA_HOOK_REGISTRY
        );
        
        console2.log("\nEncoded constructor arguments:");
        console2.logBytes(constructorArgs);
        
        console2.log("\nFORGE COMMAND:");
        console2.log("forge verify-contract \\");
        console2.log("  --rpc-url https://sepolia.base.org \\");
        console2.log("  --etherscan-api-key $BASESCAN_API_KEY \\");
        console2.log("  --constructor-args $(cast abi-encode \"constructor(address,address,address,address)\" \\");
        console2.log("    0x37f77Ad8b997B0b927DA4233C9607Cf55EDc29Fd \\");
        console2.log("    0x08928FB15DE474f89BaE21DC50b8758Cb882D5EE \\");
        console2.log("    0xe0eC17Ab9f7ce52cC60DFB64E0A0A705d02Bd040 \\");
        console2.log("    0x0000000000000000000000000000000000000000) \\");
        console2.log("  0xb4ac7Bac55f22B88C43b848f3D6d1492C4C823f1 \\");
        console2.log("  ZoraFactoryImpl");
        
        console2.log("\n" "2. VERIFY FACTORY PROXY:");
        console2.log("Contract: ZoraFactory");
        console2.log("Address:", FACTORY_PROXY);
        console2.log("Constructor args: (implementation address)");
        console2.log("  implementation:", FACTORY_IMPL);
        
        console2.log("\nFORGE COMMAND:");
        console2.log("forge verify-contract \\");
        console2.log("  --rpc-url https://sepolia.base.org \\");
        console2.log("  --etherscan-api-key $BASESCAN_API_KEY \\");
        console2.log("  --constructor-args $(cast abi-encode \"constructor(address)\" \\");
        console2.log("    0xb4ac7Bac55f22B88C43b848f3D6d1492C4C823f1) \\");
        console2.log("  0xAe028301c7822F2c254A43451D22dB5Fe447a4a0 \\");
        console2.log("  ZoraFactory");
        
        console2.log("\n=== ENVIRONMENT SETUP ===");
        console2.log("Before running verification, ensure you have:");
        console2.log("1. BASESCAN_API_KEY environment variable set");
        console2.log("2. Get your API key from: https://basescan.org/apis");
        console2.log("3. Set it: export BASESCAN_API_KEY=\"your_key_here\"");
        
        console2.log("\n=== VERIFICATION STEPS ===");
        console2.log("1. Run: forge script script/VerifyContracts.s.sol");
        console2.log("2. Copy the forge verify-contract commands above");
        console2.log("3. Run each command in your terminal");
        console2.log("4. Check BaseScan for verification success");
    }
}