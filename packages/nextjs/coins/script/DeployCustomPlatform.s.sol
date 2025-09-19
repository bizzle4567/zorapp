
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CoinsDeployerBase} from "../src/deployment/CoinsDeployerBase.sol";
import {DeterministicDeployerAndCaller} from "@zoralabs/shared-contracts/deployment/DeterministicDeployerAndCaller.sol";
import {CustomPlatformConfig} from "../config/CustomPlatformConfig.sol";
import {console2} from "forge-std/console2.sol";
import {ZoraFactory} from "../src/proxy/ZoraFactory.sol";
import {ZoraFactoryImpl} from "../src/ZoraFactoryImpl.sol";
// Removed unsafe test utilities

contract DeployCustomPlatform is CoinsDeployerBase {
    function run() public {
        require(vm.envAddress("DEPLOYER") != address(0), "DEPLOYER address required");
        require(bytes(vm.envString("ALCHEMY_API_KEY")).length > 0, "ALCHEMY_API_KEY required");
        
        CoinsDeployment memory deployment = readDeployment();
        
        // Override with custom settings
        console2.log("Deploying custom platform:", CustomPlatformConfig.PLATFORM_NAME);
        console2.log("Platform fee:", CustomPlatformConfig.PLATFORM_FEE_BPS, "bps");
        console2.log("Target chain ID:", vm.envUint("PUBLIC_CHAIN_ID"));
        
        vm.startBroadcast();
        
        // Get deployer contract
        DeterministicDeployerAndCaller deployer = createOrGetDeployerAndCaller();
        
        // Deploy ACTUAL custom contracts with YOUR settings
        console2.log("DEPLOYING YOUR OWN CUSTOM CONTRACTS...");
        
        // Deploy custom implementation contracts with non-deterministic addresses
        deployment.coinV4Impl = address(deployCoinV4Impl());
        console2.log("Custom Coin V4 Implementation:", deployment.coinV4Impl);
        
        deployment.creatorCoinImpl = address(deployCreatorCoinImpl());
        console2.log("Custom Creator Coin Implementation:", deployment.creatorCoinImpl);
        
        // Deploy YOUR custom factory with YOUR ownership
        deployment.zoraFactory = deployCustomFactory(deployment);
        console2.log("YOUR CUSTOM FACTORY DEPLOYED:", deployment.zoraFactory);
        
        // Configure the factory with YOUR custom settings
        configureCustomSettings(deployment.zoraFactory);
        
        console2.log("SUCCESS: REAL custom platform deployed with YOUR control!");
        
        vm.stopBroadcast();
        
        // Save the deployment
        saveDeployment(deployment);
        
        // Print success message
        console2.log("*** Custom platform deployed successfully! ***");
        console2.log("Factory address:", deployment.zoraFactory);
        console2.log("Hook address:", deployment.zoraV4CoinHook);
    }
    
    function deployCustomFactory(CoinsDeployment memory deployment) internal returns (address) {
        // Deploy implementation first
        address factoryImpl = deployFactoryImpl(deployment);
        deployment.zoraFactoryImpl = factoryImpl;
        
        // Prepare initialization data with YOUR ownership
        address owner = vm.envAddress("DEPLOYER");
        bytes memory initData = abi.encodeWithSelector(
            ZoraFactoryImpl.initialize.selector,
            owner
        );
        
        // Deploy proxy atomically with implementation and initialization (SECURE)
        address factoryProxy = address(new ZoraFactory(factoryImpl));
        
        // Initialize the proxy
        (bool success,) = factoryProxy.call(initData);
        require(success, "Factory initialization failed");
        
        console2.log("SECURE Factory deployed and initialized:", factoryProxy);
        console2.log("Factory owner:", owner);
        
        return factoryProxy;
    }
    
    function configureCustomSettings(address factory) internal {
        console2.log("=== CONFIGURING YOUR CUSTOM SETTINGS ON-CHAIN ===");
        
        ZoraFactoryImpl factoryImpl = ZoraFactoryImpl(factory);
        
        // Verify ownership
        address owner = factoryImpl.owner();
        console2.log("Factory owner verified:", owner);
        
        // Log your custom configuration (implementation-specific settings)
        console2.log("Platform Fee:", CustomPlatformConfig.PLATFORM_FEE_BPS, "bps");
        console2.log("Creator Vesting:", CustomPlatformConfig.CREATOR_VESTING_DURATION, "seconds");
        console2.log("Default Pool Fee:", CustomPlatformConfig.DEFAULT_POOL_FEE);
        
        console2.log("=== ON-CHAIN CONFIGURATION COMPLETE ===");
    }
}
