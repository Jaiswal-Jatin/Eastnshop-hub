import 'dart:convert';
import 'dart:developer';

import 'ApiService.dart';
import 'SharedPrefUtils.dart';
import 'TokenManager.dart';


class TokenRefreshTestHelper {

  /// Test the complete token refresh flow
  static Future<void> testTokenRefreshFlow() async {
    log('🧪 Starting Token Refresh Flow Test...');

    try {
      // Step 1: Clear any existing tokens
      await TokenManager.clearTokens();
      log('✅ Step 1: Cleared existing tokens');

      // Step 2: Simulate storing tokens after login
      await _simulateLogin();
      log('✅ Step 2: Simulated login and token storage');

      // Step 3: Test token validation
      await _testTokenValidation();
      log('✅ Step 3: Tested token validation');

      // Step 4: Test automatic token refresh
      await _testTokenRefresh();
      log('✅ Step 4: Tested token refresh');

      // Step 5: Test API calls with automatic token management
      await _testApiCallsWithTokenManagement();
      log('✅ Step 5: Tested API calls with token management');

      log('🎉 Token Refresh Flow Test Completed Successfully!');

    } catch (e) {
      log('❌ Token Refresh Flow Test Failed: $e');
    }
  }

  /// Simulate login and token storage
  static Future<void> _simulateLogin() async {
    // Simulate login response with tokens
    String mockAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjYsInJvbGUiOiJzaG9wa2VlcGVyIiwidXNlcm5hbWUiOiJOaWwiLCJpYXQiOjE3NTcyMzM3OTAsImV4cCI6MTc1NzIzNzM5MH0.6MZih0jgmWTotglD3OCDZuVl_yhNb_g_2eotdv8vgPo";
    String mockRefreshToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjYsInJvbGUiOiJzaG9wa2VlcGVyIiwidXNlcm5hbWUiOiJOaWwiLCJpYXQiOjE3NTcyMzM3OTAsImV4cCI6MTc1NzI0MDk5MH0.refresh_token_signature";

    // Store tokens using TokenManager
    await TokenManager.storeTokens(
      accessToken: mockAccessToken,
      refreshToken: mockRefreshToken,
      expiresIn: 3600, // 1 hour
    );

    // Store user data
    await SharedPrefUtils.init();
    await SharedPrefUtils.setString('user_id', '6');
    await SharedPrefUtils.setString('user_role', 'shopkeeper');
    await SharedPrefUtils.setString('username', 'TestUser');

    log('📝 Stored mock tokens and user data');
  }

  /// Test token validation
  static Future<void> _testTokenValidation() async {
    // Test authentication status
    bool isAuthenticated = await TokenManager.isAuthenticated();
    log('🔐 Is Authenticated: $isAuthenticated');

    // Test token expiry check
    bool isExpired = await TokenManager.isTokenExpiredOrExpiringSoon();
    log('⏰ Is Token Expired/Expiring Soon: $isExpired');

    // Get token info
    var tokenInfo = await TokenManager.getTokenInfo();
    log('📊 Token Info: $tokenInfo');
  }

  /// Test token refresh functionality
  static Future<void> _testTokenRefresh() async {
    log('🔄 Testing token refresh...');

    // Get current refresh token
    String? refreshToken = await TokenManager.getRefreshToken();
    log('🔄 Current Refresh Token: ${refreshToken?.substring(0, 20)}...');

    // Note: This will fail in test environment since we don't have a real server
    // In real usage, this would call the actual refresh endpoint
    int refreshResult = await TokenManager.refreshAccessToken();
    log('🔄 Token Refresh Result Code: $refreshResult');
    bool refreshSuccess = refreshResult == TokenManager.refreshSuccess;
    log('🔄 Token Refresh Success: $refreshSuccess');

    if (!refreshSuccess) {
      log('⚠️ Token refresh failed (expected in test environment)');
    }
  }

  /// Test API calls with automatic token management
  static Future<void> _testApiCallsWithTokenManagement() async {
    log('🌐 Testing API calls with token management...');

    // Test getting valid access token
    String? validToken = await TokenManager.getValidAccessToken();
    log('🔐 Valid Access Token: ${validToken?.substring(0, 20)}...');

    // Test API service authentication check
    bool isApiAuthenticated = await ApiService.isAuthenticated();
    log('🔐 API Service Authentication: $isApiAuthenticated');
  }

  /// Test token expiry scenarios
  static Future<void> testTokenExpiryScenarios() async {
    log('🧪 Testing Token Expiry Scenarios...');

    try {
      // Scenario 1: Valid token
      await _simulateLogin();
      bool isValid = await TokenManager.isTokenExpiredOrExpiringSoon();
      log('📊 Scenario 1 - Valid Token: ${!isValid}');

      // Scenario 2: Expired token (simulate by storing old token)
      String expiredToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjYsInJvbGUiOiJzaG9wa2VlcGVyIiwidXNlcm5hbWUiOiJOaWwiLCJpYXQiOjE1NzI4MzM3OTAsImV4cCI6MTU3MjgzNzM5MH0.expired_token_signature";

      await TokenManager.storeTokens(
        accessToken: expiredToken,
        refreshToken: "expired_refresh_token",
        expiresIn: 3600,
      );

      bool isExpired = await TokenManager.isTokenExpiredOrExpiringSoon();
      log('📊 Scenario 2 - Expired Token: $isExpired');

      // Scenario 3: No token
      await TokenManager.clearTokens();
      bool hasNoToken = await TokenManager.isAuthenticated();
      log('📊 Scenario 3 - No Token: ${!hasNoToken}');

      log('✅ Token Expiry Scenarios Test Completed');

    } catch (e) {
      log('❌ Token Expiry Scenarios Test Failed: $e');
    }
  }

  /// Demonstrate the complete authentication flow
  static Future<void> demonstrateCompleteFlow() async {
    log('🎯 Demonstrating Complete Authentication Flow...');

    try {
      // Step 1: Clear everything
      await TokenManager.clearTokens();
      await SharedPrefUtils.init();
      await SharedPrefUtils.clearAll();
      log('🧹 Step 1: Cleared all data');

      // Step 2: Simulate user login
      await _simulateLogin();
      log('👤 Step 2: User logged in');

      // Step 3: Show token information
      var tokenInfo = await TokenManager.getTokenInfo();
      log('📋 Step 3: Token Information: $tokenInfo');

      // Step 4: Test API authentication
      bool canMakeApiCalls = await ApiService.isAuthenticated();
      log('🌐 Step 4: Can make API calls: $canMakeApiCalls');

      // Step 5: Simulate token refresh (will fail in test)
      log('🔄 Step 5: Attempting token refresh...');
      int refreshResultCode = await TokenManager.refreshAccessToken();
      bool refreshSuccess = refreshResultCode == TokenManager.refreshSuccess;
      log('🔄 Step 5: Token refresh result code: $refreshResultCode, Success: $refreshSuccess');

      // Step 6: Show final state
      var finalTokenInfo = await TokenManager.getTokenInfo();
      log('📋 Step 6: Final Token Information: $finalTokenInfo');

      log('🎉 Complete Authentication Flow Demonstration Finished!');

    } catch (e) {
      log('❌ Authentication Flow Demonstration Failed: $e');
    }
  }

  /// Clear all test data
  static Future<void> clearTestData() async {
    log('🧹 Clearing test data...');
    await TokenManager.clearTokens();
    await SharedPrefUtils.init();
    await SharedPrefUtils.clearAll();
    log('✅ Test data cleared');
  }
}
