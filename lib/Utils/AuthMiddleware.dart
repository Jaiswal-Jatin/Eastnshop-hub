import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';

import '../Routes/App_Pages.dart';
import 'SharedPrefUtils.dart';
import 'TokenManager.dart';

class AuthMiddleware {
  // Check if token is valid and not expired
  static Future<bool> isTokenValid() async {
    try {
      // Use TokenManager to check if token is valid
      bool isValid = await TokenManager.isAuthenticated() && 
                     !await TokenManager.isTokenExpiredOrExpiringSoon();
      
      if (isValid) {
        log('✅ Token is valid');
      } else {
        log('🔒 Token is invalid or expired');
      }
      
      return isValid;
    } catch (e) {
      log('🔒 Error checking token validity: $e');
      return false;
    }
  }
  
  // Handle authentication errors and redirect to login
  static Future<void> handleAuthError() async {
    log('🔒 Authentication error - redirecting to login');
    
    // Clear all tokens and authentication data
    await TokenManager.clearTokens();
    await SharedPrefUtils.init();
    await SharedPrefUtils.remove('user_role');
    await SharedPrefUtils.remove('user_id');
    await SharedPrefUtils.remove('username');
    await SharedPrefUtils.remove('user_email');
    await SharedPrefUtils.remove('user_phone');
    
    // Redirect to login
    Get.offAllNamed(AppRoutes.login);
  }
  
  // Validate token before API calls - attempts refresh if needed
  static Future<bool> validateTokenBeforeApiCall() async {
    // try to get a valid token (this handles refresh automatically)
    String? token = await TokenManager.getValidAccessToken();
    
    if (token == null || token.isEmpty) {
      log('🔒 No valid token available even after refresh attempt - redirecting to login');
      await handleAuthError();
      return false;
    }
    
    return true;
  }
  
  // Get token info for debugging
  static Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      // Use TokenManager to get token info
      return await TokenManager.getTokenInfo();
    } catch (e) {
      log('Error getting token info: $e');
      return null;
    }
  }
}
