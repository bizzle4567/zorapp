
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library CustomPlatformConfig {
    /// @notice Your custom platform name
    string public constant PLATFORM_NAME = "YourCoinPlatform";
    
    /// @notice Your custom platform fee (in basis points, 250 = 2.5%)
    uint256 public constant PLATFORM_FEE_BPS = 250;
    
    /// @notice Custom creator vesting duration (1 year)
    uint256 public constant CREATOR_VESTING_DURATION = 365 days;
    
    /// @notice Custom market maker fee (0.3% = 3000 fee units in Uniswap V4)
    uint24 public constant DEFAULT_POOL_FEE = 3000;
    
    /// @notice Custom tick spacing for pools
    int24 public constant DEFAULT_TICK_SPACING = 60;
    
    /// @notice Minimum liquidity for new pools
    uint128 public constant MIN_LIQUIDITY = 1000;
    
    /// @notice Maximum coins per creator (0 = unlimited)
    uint256 public constant MAX_COINS_PER_CREATOR = 0;
    
    /// @notice Enable/disable certain features
    bool public constant ALLOW_CREATOR_COINS = true;
    bool public constant ALLOW_CONTENT_COINS = true;
    bool public constant REQUIRE_WHITELIST = false;
}
