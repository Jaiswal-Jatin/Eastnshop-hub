import 'dart:developer';

import 'ApiService.dart';
import 'AuthMiddleware.dart';
import 'SharedPrefUtils.dart';


class AuthTestHelper {
  // Test authentication flow
  static Future<void> testAuthFlow() async {
    log('🧪 Testing Authentication Flow...');

    // Test 1: Check if user is authenticated
    bool isAuth = await ApiService.isAuthenticated();
    log('✅ User authenticated: $isAuth');

    // Test 2: Get current user info
    var userInfo = await ApiService.getCurrentUser();
    log('✅ Current user info: $userInfo');

    // Test 3: Get token info
    var tokenInfo = await AuthMiddleware.getTokenInfo();
    log('✅ Token info: $tokenInfo');

    // Test 4: Test token validity
    bool isValid = await AuthMiddleware.isTokenValid();
    log('✅ Token valid: $isValid');

    // Test 5: Test API call with authentication
    try {
      log('🧪 Testing authenticated API call...');
      var response = await ApiService.get('/api/shop/user/6');
      log('✅ API call successful: ${response.statusCode}');
    } catch (e) {
      log('❌ API call failed: $e');
    }
  }

  // Test token storage and retrieval
  static Future<void> testTokenStorage() async {
    log('🧪 Testing Token Storage...');

    await SharedPrefUtils.init();

    // Test storing token
    String testToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjYsInJvbGUiOiJzaG9wa2VlcGVyIiwidXNlcm5hbWUiOiJOaWwiLCJpYXQiOjE3NTcyMzM3OTAsImV4cCI6MTc1NzIzNzM5MH0.6MZih0jgmWTotglD3OCDZuVl_yhNb_g_2eotdv8vgPo";

    await SharedPrefUtils.setString('auth_token', testToken);
    await SharedPrefUtils.setString('user_id', '6');
    await SharedPrefUtils.setString('user_role', 'shopkeeper');
    await SharedPrefUtils.setBool('is_logged_in', true);

    log('✅ Token stored successfully');

    // Test retrieving token
    String? retrievedToken = SharedPrefUtils.getString('auth_token');
    log('✅ Retrieved token: ${retrievedToken?.substring(0, 20)}...');

    // Test token validation
    bool isValid = await AuthMiddleware.isTokenValid();
    log('✅ Token validation: $isValid');

    // Test token info
    var tokenInfo = await AuthMiddleware.getTokenInfo();
    log('✅ Token info: $tokenInfo');
  }

  // Clear test data
  static Future<void> clearTestData() async {
    log('🧹 Clearing test data...');
    await ApiService.clearAuth();
    log('✅ Test data cleared');
  }
}
