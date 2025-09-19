#!/bin/bash

# Contract Verification Script for Base Sepolia
# This script verifies the ZoraFactoryImpl and ZoraFactory contracts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ZORA CONTRACT VERIFICATION SCRIPT ===${NC}"
echo ""

# Check if BASESCAN_API_KEY is set
if [ -z "$BASESCAN_API_KEY" ]; then
    echo -e "${RED}ERROR: BASESCAN_API_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}Please get your API key from https://basescan.org/apis${NC}"
    echo -e "${YELLOW}Then set it: export BASESCAN_API_KEY=\"your_key_here\"${NC}"
    exit 1
fi

echo -e "${GREEN}✓ BASESCAN_API_KEY is set${NC}"
echo ""

# Contract addresses
FACTORY_IMPL="0xb4ac7Bac55f22B88C43b848f3D6d1492C4C823f1"
FACTORY_PROXY="0xAe028301c7822F2c254A43451D22dB5Fe447a4a0"

# Constructor arguments
COIN_V4_IMPL="0x37f77Ad8b997B0b927DA4233C9607Cf55EDc29Fd"
CREATOR_COIN_IMPL="0x08928FB15DE474f89BaE21DC50b8758Cb882D5EE"
HOOK="0xe0eC17Ab9f7ce52cC60DFB64E0A0A705d02Bd040"
ZORA_HOOK_REGISTRY="0x0000000000000000000000000000000000000000"

echo -e "${YELLOW}Verifying ZoraFactoryImpl (Implementation)...${NC}"
echo "Address: $FACTORY_IMPL"

# Verify Factory Implementation
if forge verify-contract \
    --rpc-url https://sepolia.base.org \
    --etherscan-api-key $BASESCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address)" \
        $COIN_V4_IMPL \
        $CREATOR_COIN_IMPL \
        $HOOK \
        $ZORA_HOOK_REGISTRY) \
    $FACTORY_IMPL \
    ZoraFactoryImpl; then
    echo -e "${GREEN}✓ ZoraFactoryImpl verification successful!${NC}"
else
    echo -e "${RED}✗ ZoraFactoryImpl verification failed${NC}"
fi

echo ""
echo -e "${YELLOW}Verifying ZoraFactory (Proxy)...${NC}"
echo "Address: $FACTORY_PROXY"

# Verify Factory Proxy
if forge verify-contract \
    --rpc-url https://sepolia.base.org \
    --etherscan-api-key $BASESCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $FACTORY_IMPL) \
    $FACTORY_PROXY \
    ZoraFactory; then
    echo -e "${GREEN}✓ ZoraFactory verification successful!${NC}"
else
    echo -e "${RED}✗ ZoraFactory verification failed${NC}"
fi

echo ""
echo -e "${GREEN}=== VERIFICATION COMPLETE ===${NC}"
echo -e "${YELLOW}Check your contracts on BaseScan:${NC}"
echo "Factory Implementation: https://sepolia.basescan.org/address/$FACTORY_IMPL"
echo "Factory Proxy: https://sepolia.basescan.org/address/$FACTORY_PROXY"