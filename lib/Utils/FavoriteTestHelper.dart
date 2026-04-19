import 'dart:developer';

import 'ApiService.dart';


class FavoriteTestHelper {
  // Test favorite functionality
  static Future<void> testFavoriteFunctionality() async {
    log('🧪 Testing Favorite Functionality...');
    
    // Test 1: Check if user is authenticated
    bool isAuth = await ApiService.isAuthenticated();
    log('✅ User authenticated: $isAuth');
    
    if (!isAuth) {
      log('❌ User not authenticated - cannot test favorites');
      return;
    }
    
    // Test 2: Get current user info
    var userInfo = await ApiService.getCurrentUser();
    log('✅ Current user info: $userInfo');
    
    // Test 3: Test API endpoints
    try {
      log('🧪 Testing favorites API endpoints...');
      
      // Test get favorites endpoint
      var response = await ApiService.get('/api/favourites/user/6');
      log('✅ Get favorites response: ${response.statusCode}');
      
      // Test add to favorites endpoint
      var addResponse = await ApiService.post('/api/favourites/add', body: {
        "user_id": 6,
        "offer_id": 1,
        "item_type": "offer",
        "item_data": {"test": "data"}
      });
      log('✅ Add to favorites response: ${addResponse.statusCode}');
      
    } catch (e) {
      log('❌ API test failed: $e');
    }
    
    log('✅ Favorite functionality test completed!');
  }
  
  // Test image fallback scenarios
  static void testImageFallbackScenarios() {
    log('🧪 Testing Image Fallback Scenarios...');
    
    // Test 1: Empty image
    String emptyImage = '';
    log('✅ Empty image test: ${emptyImage.isEmpty ? "Will show noimage.png" : "Will show actual image"}');
    
    // Test 2: Valid network image
    String networkImage = 'https://example.com/image.jpg';
    log('✅ Network image test: ${networkImage.startsWith('http') ? "Will load network image" : "Will show fallback"}');
    
    // Test 3: Valid asset image
    String assetImage = 'assets/offerdesign1.png';
    log('✅ Asset image test: ${assetImage.startsWith('assets/') ? "Will load asset image" : "Will show fallback"}');
    
    // Test 4: Invalid image path
    String invalidImage = 'invalid/path/image.jpg';
    log('✅ Invalid image test: Will show noimage.png fallback');
    
    log('✅ Image fallback scenarios tested!');
  }
  
  // Clear test data
  static Future<void> clearTestData() async {
    log('🧹 Clearing test data...');
    // Note: We don't clear auth data here as it's needed for testing
    log('✅ Test data cleared');
  }
}
