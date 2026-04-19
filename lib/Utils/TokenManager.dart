import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../Routes/App_Pages.dart';
import 'SharedPrefUtils.dart';

class TokenManager {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isLoggedInKey = 'is_logged_in';
  
  // Enum to track token refresh results
  static const int refreshSuccess = 0;
  static const int refreshAuthFailure = 1;
  static const int refreshTransientFailure = 2; // Network Error, Server Error, etc.
  
  // Token refresh endpoint
  static const String _refreshEndpoint = '/api/auth/refresh-token';
  
  // Singleton instance
  static TokenManager? _instance;
  static TokenManager get instance => _instance ??= TokenManager._();
  TokenManager._();
  
  // Future to synchronize token refresh calls
  static Future<int>? _refreshFuture;
  
  /// Store tokens after successful login
  static Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    dynamic expiresIn, // Use dynamic to handle potential string from API
  }) async {
    try {
      await SharedPrefUtils.init();
      
      // Store access token
      await SharedPrefUtils.setString(_accessTokenKey, accessToken);
      
      // Store refresh token if provided
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await SharedPrefUtils.setString(_refreshTokenKey, refreshToken);
      } else {
        // Log if refresh token is missing
        log('⚠️ No refresh token provided to storeTokens');
      }
      
      // Calculate and store expiry time
      int? expSeconds;
      if (expiresIn != null) {
        if (expiresIn is int) {
          expSeconds = expiresIn;
        } else if (expiresIn is String) {
          expSeconds = int.tryParse(expiresIn);
        }
      }
      
      if (expSeconds != null) {
        int expiryTime = DateTime.now().millisecondsSinceEpoch + (expSeconds * 1000);
        await SharedPrefUtils.setString(_tokenExpiryKey, expiryTime.toString());
        log('🕐 Token set to expire at: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
      } else {
        // Default to 24 hours if no valid expiry provided
        int expiryTime = DateTime.now().millisecondsSinceEpoch + (86400 * 1000);
        await SharedPrefUtils.setString(_tokenExpiryKey, expiryTime.toString());
        log('🕐 No valid expiry provided, defaulting to 24 hours');
      }
      
      // Set logged in status
      await SharedPrefUtils.setBool(_isLoggedInKey, true);
      
      log('✅ Tokens stored successfully');
    } catch (e) {
      log('❌ Error storing tokens: $e');
      rethrow;
    }
  }
  
  /// Get current access token
  static Future<String?> getAccessToken() async {
    await SharedPrefUtils.init();
    return SharedPrefUtils.getString(_accessTokenKey);
  }
  
  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    await SharedPrefUtils.init();
    return SharedPrefUtils.getString(_refreshTokenKey);
  }
  
  /// Check if token is expired or will expire soon (within 5 minutes)
  static Future<bool> isTokenExpiredOrExpiringSoon() async {
    try {
      await SharedPrefUtils.init();
      
      String? expiryTimeStr = SharedPrefUtils.getString(_tokenExpiryKey);
      if (expiryTimeStr == null || expiryTimeStr.isEmpty) {
        // If no expiry time stored, check JWT token directly
        return await _isJWTTokenExpired();
      }
      
      int expiryTime = int.tryParse(expiryTimeStr) ?? 0;
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Consider token expired if it expires within 5 minutes (300000 ms)
      bool isExpired = currentTime >= (expiryTime - 300000);
      
      if (isExpired) {
        log('🕐 Token expiry check: Expired or expiring within 5 minutes');
      }
      return isExpired;
    } catch (e) {
      log('❌ Error checking token expiry: $e');
      return true; // Assume expired on error to be safe
    }
  }
  
  /// Check if JWT token is expired by decoding it
  static Future<bool> _isJWTTokenExpired() async {
    try {
      String? token = await getAccessToken();
      if (token == null || token.isEmpty) return true;
      
      // JWT tokens have 3 parts separated by dots
      List<String> parts = token.split('.');
      if (parts.length != 3) return true;
      
      // Decode the payload (second part)
      String payload = parts[1];
      
      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      // Decode base64
      String decodedPayload = utf8.decode(base64Decode(payload));
      Map<String, dynamic> payloadData = jsonDecode(decodedPayload);
      
      // Check expiration
      int? exp = payloadData['exp'];
      if (exp != null) {
        int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return currentTime >= (exp - 300); // 5 minute buffer
      }
      
      return false;
    } catch (e) {
      log('❌ Error decoding JWT token: $e');
      return true;
    }
  }
  
  /// Refresh access token using refresh token (synchronized)
  /// Returns: 0 for success, 1 for auth failure (401/403), 2 for transient failure
  static Future<int> refreshAccessToken() async {
    // If a refresh is already in progress, wait for it instead of starting a new one
    if (_refreshFuture != null) {
      log('🔄 Token refresh already in progress, waiting for it...');
      return await _refreshFuture!;
    }

    // Start a new refresh operation
    _refreshFuture = _performRefresh();
    
    try {
      return await _refreshFuture!;
    } finally {
      // Clear the future when done
      _refreshFuture = null;
    }
  }

  /// Internal method to perform the actual refresh logic
  static Future<int> _performRefresh() async {
    try {
      String? refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        log('❌ Cannot refresh: No refresh token available in storage');
        return refreshAuthFailure;
      }
      
      log('🔄 Attempting to refresh access token with backend...');
      
      final response = await http.post(
        Uri.parse('${AppRoutes.domainName}$_refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      ).timeout(const Duration(seconds: 15));
      
      log('🔄 Refresh response received: Status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> data = jsonDecode(response.body);
          
          // Extract new tokens from response
          String? newAccessToken = data['token'] ?? 
                                 data['access_token'] ?? 
                                 data['accessToken'];
          
          String? newRefreshToken = data['refresh_token'] ?? 
                                   data['refreshToken'];
          
          dynamic expiresIn = data['expires_in'] ?? 
                             data['expiresIn'];
          
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Store new tokens
            await storeTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken, // Update refresh token if server provides a new one
              expiresIn: expiresIn,
            );
            
            log('✅ Token refresh successful');
            return refreshSuccess;
          } else {
            log('❌ Refresh response missing access token: ${response.body}');
            return refreshAuthFailure;
          }
        } catch (e) {
          log('❌ Error parsing successful refresh response: $e');
          return refreshTransientFailure;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        log('❌ Token refresh failed (HTTP ${response.statusCode}): ${response.body}');
        return refreshAuthFailure;
      } else {
        log('⚠️ Token refresh transient failure (HTTP ${response.statusCode}): ${response.body}');
        return refreshTransientFailure;
      }
    } catch (e) {
      log('⚠️ Exception during token refresh: $e');
      return refreshTransientFailure;
    }
  }
  
  /// Get valid access token (refresh if needed)
  static Future<String?> getValidAccessToken() async {
    try {
      // Check if token is expired or expiring soon
      if (await isTokenExpiredOrExpiringSoon()) {
        log('🔄 Token needs refresh before API call');
        
        // Try to refresh the token (using the synchronized method)
        int refreshResult = await refreshAccessToken();
        
        if (refreshResult == refreshAuthFailure) {
          log('❌ Could not get valid token: Refresh failed (Auth Error)');
          // Note: We don't call clearTokens here to allow ApiService to handle 401
          return null;
        } else if (refreshResult == refreshTransientFailure) {
          log('⚠️ Token refresh transient failure, returning current token as fallback');
          return await getAccessToken();
        }
      }
      
      // Return the current access token
      return await getAccessToken();
    } catch (e) {
      log('❌ Error in getValidAccessToken: $e');
      return null;
    }
  }

  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    await SharedPrefUtils.init();
    
    String? accessToken = SharedPrefUtils.getString(_accessTokenKey);
    bool isLoggedIn = SharedPrefUtils.getBool(_isLoggedInKey);
    
    return accessToken != null && accessToken.isNotEmpty && isLoggedIn;
  }
  
  /// Clear all tokens and authentication data
  static Future<void> clearTokens() async {
    try {
      await SharedPrefUtils.init();
      
      await SharedPrefUtils.remove(_accessTokenKey);
      await SharedPrefUtils.remove(_refreshTokenKey);
      await SharedPrefUtils.remove(_tokenExpiryKey);
      await SharedPrefUtils.setBool(_isLoggedInKey, false);
      
      log('🧹 All tokens cleared');
    } catch (e) {
      log('❌ Error clearing tokens: $e');
    }
  }
  
  /// Get token information for debugging
  static Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      String? accessToken = await getAccessToken();
      String? refreshToken = await getRefreshToken();
      
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      
      // Decode JWT token
      List<String> parts = accessToken.split('.');
      if (parts.length != 3) {
        return null;
      }
      
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      String decodedPayload = utf8.decode(base64Decode(payload));
      Map<String, dynamic> payloadData = jsonDecode(decodedPayload);
      
      return {
        'accessToken': '${accessToken.substring(0, 20)}...',
        'refreshToken': refreshToken != null ? '${refreshToken.substring(0, 20)}...' : 'Not available',
        'userId': payloadData['userId'] ?? payloadData['user_id'],
        'role': payloadData['role'],
        'username': payloadData['username'],
        'iat': payloadData['iat'],
        'exp': payloadData['exp'],
        'expiresAt': DateTime.fromMillisecondsSinceEpoch((payloadData['exp'] ?? 0) * 1000),
        'isExpired': DateTime.now().millisecondsSinceEpoch ~/ 1000 >= (payloadData['exp'] ?? 0),
        'isAuthenticated': await isAuthenticated(),
      };
    } catch (e) {
      log('❌ Error getting token info: $e');
      return null;
    }
  }
}
