// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {ZoraFactoryImpl} from "../src/ZoraFactoryImpl.sol";
import {CoinConfigurationVersions} from "../src/libs/CoinConfigurationVersions.sol";
import {PoolConfiguration} from "../src/types/PoolConfiguration.sol";
import {CreatorCoinConstants} from "../src/libs/CreatorCoinConstants.sol";

/// @title TestCoinCreation
/// @notice Script to test coin creation using our deployed custom factory
contract TestCoinCreation is Script {
    
    // Your deployed factory address
    address constant CUSTOM_FACTORY = 0xAe028301c7822F2c254A43451D22dB5Fe447a4a0;
    
    // ZORA token address required for creator coins
    address constant ZORA_TOKEN = CreatorCoinConstants.CURRENCY;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== PHASE 4: TESTING COIN CREATION ===");
        console2.log("Using custom factory:", CUSTOM_FACTORY);
        console2.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create Test Coin 1: Artist Creator Coin
        address testCoin1 = createTestCoin1(deployer);
        console2.log("Test Coin 1 (Artist) deployed:", testCoin1);
        
        // Create Test Coin 2: Musician Creator Coin  
        address testCoin2 = createTestCoin2(deployer);
        console2.log("Test Coin 2 (Musician) deployed:", testCoin2);
        
        vm.stopBroadcast();
        
        console2.log("=== COIN CREATION TEST COMPLETE ===");
        console2.log("Successfully created 2 test coins on your platform!");
    }
    
    function createTestCoin1(address deployer) internal returns (address) {
        console2.log("\n--- Creating Test Coin 1: Digital Artist ---");
        
        ZoraFactoryImpl factory = ZoraFactoryImpl(CUSTOM_FACTORY);
        
        // Coin 1 parameters
        address payoutRecipient = deployer; // Creator receives payouts
        address[] memory owners = new address[](1);
        owners[0] = deployer; // Creator can manage coin
        
        string memory uri = "https://ipfs.io/ipfs/QmTestArtist1234567890"; // Test metadata URI
        string memory name = "Digital Artist Coin";
        string memory symbol = "DARTIST";
        
        // Build pool configuration for ETH-backed coin
        bytes memory poolConfig = buildPoolConfig();
        
        address platformReferrer = address(0); // No referrer for test
        bytes32 coinSalt = keccak256("ARTIST_COIN_2025");
        
        return factory.deployCreatorCoin(
            payoutRecipient,
            owners,
            uri,
            name,
            symbol,
            poolConfig,
            platformReferrer,
            coinSalt
        );
    }
    
    function createTestCoin2(address deployer) internal returns (address) {
        console2.log("\n--- Creating Test Coin 2: Indie Musician ---");
        
        ZoraFactoryImpl factory = ZoraFactoryImpl(CUSTOM_FACTORY);
        
        // Coin 2 parameters
        address payoutRecipient = deployer; // Creator receives payouts
        address[] memory owners = new address[](1);
        owners[0] = deployer; // Creator can manage coin
        
        string memory uri = "https://ipfs.io/ipfs/QmTestMusician9876543210"; // Test metadata URI
        string memory name = "Indie Musician Token";
        string memory symbol = "MUSIC";
        
        // Build pool configuration for ETH-backed coin
        bytes memory poolConfig = buildPoolConfig();
        
        address platformReferrer = address(0); // No referrer for test
        bytes32 coinSalt = keccak256("MUSICIAN_COIN_2025");
        
        return factory.deployCreatorCoin(
            payoutRecipient,
            owners,
            uri,
            name,
            symbol,
            poolConfig,
            platformReferrer,
            coinSalt
        );
    }
    
    function buildPoolConfig() internal pure returns (bytes memory) {
        // Build pool configuration for ETH-backed creator coin
        // Based on the test pattern from CreatorCoin.t.sol
        
        int24[] memory tickLower = new int24[](1);
        int24[] memory tickUpper = new int24[](1);
        uint16[] memory numDiscoveryPositions = new uint16[](1);
        uint256[] memory maxDiscoverySupplyShare = new uint256[](1);

        // Set tick ranges for the liquidity curve
        tickLower[0] = -138_000;
        tickUpper[0] = 81_000;
        numDiscoveryPositions[0] = 11;
        maxDiscoverySupplyShare[0] = 0.05e18; // 5% max discovery supply share
        
        // Encode configuration with all required parameters
        return abi.encode(
            CoinConfigurationVersions.DOPPLER_MULTICURVE_UNI_V4_POOL_VERSION,
            ZORA_TOKEN, // Currency (ZORA token required for creator coins)
            tickLower,
            tickUpper,
            numDiscoveryPositions,
            maxDiscoverySupplyShare
        );
    }
}