import 'dart:developer';

import 'ApiService.dart';
import 'SharedPrefUtils.dart';


class UsernameTestHelper {
  // Test username storage and retrieval
  static Future<void> testUsernameStorage() async {
    log('🧪 Testing Username Storage...');
    
    await SharedPrefUtils.init();
    
    // Test storing username
    String testUsername = "Nil";
    await SharedPrefUtils.setString('username', testUsername);
    
    log('✅ Username stored: $testUsername');
    
    // Test retrieving username
    String? retrievedUsername = SharedPrefUtils.getString('username');
    log('✅ Retrieved username: $retrievedUsername');
    
    // Test getCurrentUser method
    var userInfo = await ApiService.getCurrentUser();
    log('✅ Current user info: $userInfo');
    
    if (userInfo != null && userInfo['username'] == testUsername) {
      log('✅ Username correctly stored and retrieved!');
    } else {
      log('❌ Username storage/retrieval failed!');
    }
  }
  
  // Clear test data
  static Future<void> clearTestData() async {
    log('🧹 Clearing test data...');
    await ApiService.clearAuth();
    log('✅ Test data cleared');
  }
}
