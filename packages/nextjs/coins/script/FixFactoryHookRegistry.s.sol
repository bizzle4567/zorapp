// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {ZoraFactoryImpl} from "../src/ZoraFactoryImpl.sol";
import {ZoraV4CoinHook} from "../src/hooks/ZoraV4CoinHook.sol";
import {ZoraHookRegistry} from "../src/hook-registry/ZoraHookRegistry.sol";
import {IDeployedCoinVersionLookup} from "../src/interfaces/IDeployedCoinVersionLookup.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooksUpgradeGate} from "../src/interfaces/IHooksUpgradeGate.sol";

/// @title FixFactoryHookRegistry
/// @notice Script to deploy new hook/registry and upgrade factory to fix version lookup issue
contract FixFactoryHookRegistry is Script {
    
    // Your existing custom factory proxy
    address constant CUSTOM_FACTORY = 0xAe028301c7822F2c254A43451D22dB5Fe447a4a0;
    
    // Base Sepolia addresses
    address constant POOL_MANAGER = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant UPGRADE_GATE = 0xaF88840cb637F2684A9E460316b1678AD6245e4a; // Using existing upgrade gate
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== FIXING FACTORY HOOK REGISTRY CONFIGURATION ===");
        console2.log("Factory to fix:", CUSTOM_FACTORY);
        console2.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy new ZoraHookRegistry 
        console2.log("\n--- Step 1: Deploying new Hook Registry ---");
        ZoraHookRegistry hookRegistry = new ZoraHookRegistry();
        console2.log("Hook Registry deployed:", address(hookRegistry));
        
        // Step 2: Deploy new ZoraV4CoinHook pointing to our factory as version lookup
        console2.log("\n--- Step 2: Deploying new Hook with correct version lookup ---");
        
        // Set up trusted message senders (empty for now)
        address[] memory trustedMessageSenders = new address[](0);
        
        ZoraV4CoinHook newHook = new ZoraV4CoinHook(
            IPoolManager(POOL_MANAGER),
            IDeployedCoinVersionLookup(CUSTOM_FACTORY), // Point to our factory for version lookup!
            trustedMessageSenders,
            IHooksUpgradeGate(UPGRADE_GATE)
        );
        console2.log("New Hook deployed:", address(newHook));
        
        // Step 3: Get current factory implementation addresses
        ZoraFactoryImpl currentFactory = ZoraFactoryImpl(CUSTOM_FACTORY);
        address coinV4Impl = currentFactory.coinV4Impl();
        address creatorCoinImpl = currentFactory.creatorCoinImpl();
        console2.log("\n--- Step 3: Current Factory Configuration ---");
        console2.log("Coin V4 Implementation:", coinV4Impl);
        console2.log("Creator Coin Implementation:", creatorCoinImpl);
        
        // Step 4: Deploy new factory implementation with correct hook and registry
        console2.log("\n--- Step 4: Deploying new Factory Implementation ---");
        ZoraFactoryImpl newFactoryImpl = new ZoraFactoryImpl(
            coinV4Impl,           // Keep same coin implementation
            creatorCoinImpl,      // Keep same creator coin implementation
            address(newHook),     // Use new hook that points to our factory
            address(hookRegistry) // Use new hook registry
        );
        console2.log("New Factory Implementation deployed:", address(newFactoryImpl));
        
        // Step 5: Upgrade the factory proxy (this also registers the hook automatically)
        console2.log("\n--- Step 5: Upgrading Factory Proxy ---");
        currentFactory.upgradeToAndCall(address(newFactoryImpl), "");
        console2.log("Factory proxy upgraded successfully!");
        
        // Step 6: Verify the upgrade worked
        console2.log("\n--- Step 6: Verifying Upgrade ---");
        address newHookFromFactory = currentFactory.hook();
        address newRegistryFromFactory = currentFactory.zoraHookRegistry();
        console2.log("Factory now uses hook:", newHookFromFactory);
        console2.log("Factory now uses registry:", newRegistryFromFactory);
        
        // Verify addresses match what we deployed
        require(newHookFromFactory == address(newHook), "Hook address mismatch");
        require(newRegistryFromFactory == address(hookRegistry), "Registry address mismatch");
        
        vm.stopBroadcast();
        
        console2.log("\n=== FACTORY HOOK REGISTRY FIX COMPLETE ===");
        console2.log("SUCCESS: New Hook Registry:", address(hookRegistry));
        console2.log("SUCCESS: New Hook (points to factory):", address(newHook));
        console2.log("SUCCESS: New Factory Implementation:", address(newFactoryImpl));
        console2.log("SUCCESS: Factory proxy upgraded and hook registered");
        console2.log("\nYour factory should now be able to create coins successfully!");
    }
}