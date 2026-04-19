import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Constants/GlobalVariables.dart';
import '../Routes/App_Pages.dart';
import '../Services/FcmService.dart';
import '../Services/OtpService.dart';
import '../Utils/ApiService.dart';
import '../Utils/SharedPrefUtils.dart';
import '../Utils/TokenManager.dart';

class LoginController extends GetxController {
  TextEditingController uNameController = TextEditingController();
  TextEditingController eMailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController createPassController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController userrole = TextEditingController();
  RxBool isUploadingData = false.obs;

  void clearFormFields() {
    uNameController.clear();
    eMailController.clear();
    phoneController.clear();
    otpController.clear();
    createPassController.clear();
    confirmPassController.clear();
    userrole.clear();
    // Clear OTP ticket when form is cleared
    OtpService.clearSignupOtpTicket();
  }

  // Validation functions

  bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Logout method to clear authentication state
  Future<void> logout() async {
    await ApiService.clearAuth();
    await SharedPrefUtils.init();
    await SharedPrefUtils.remove('username'); // Clear username as well
    clearFormFields();

    // Reset global state variables
    resetGlobalState();

    Get.offAllNamed(AppRoutes.appStart);
  }

  Future<Map<String, dynamic>> registerNewUser() async {
    if (uNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        createPassController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      return {
        'success': false,
        'message': 'Please fill all the required fields!',
      };
    }

    // Validate phone number (10 digits)
    if (!isValidPhone(phoneController.text.trim())) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit phone number!',
      };
    }

    // Validate password length (minimum 6 characters)
    if (!isValidPassword(createPassController.text.trim())) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters long!',
      };
    }

    if (createPassController.text.trim() != confirmPassController.text.trim()) {
      return {'success': false, 'message': 'Passwords do not match!'};
    }

    // Check if OTP ticket exists for signup
    final otpTicket = await OtpService.getSignupOtpTicket();
    if (otpTicket == null) {
      log('❌ Registration failed: OTP ticket is null');
      return {
        'success': false,
        'message':
            'OTP verification required. Please verify your phone number first.',
      };
    }
    log('✅ OTP ticket found: ${otpTicket.substring(0, 20)}...');

    isUploadingData.value = true;

    try {
      final body = jsonEncode({
        "username": uNameController.text.trim(),
        "email": eMailController.text.trim().isEmpty
            ? ""
            : eMailController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": createPassController.text,
        "role": userrole.text,
      });

      log("api/auth/signup : $body");

      final response = await ApiService.postWithCustomHeaders(
        '/api/auth/signup',
        body: {
          "username": uNameController.text.trim(),
          "email": eMailController.text.trim().isEmpty
              ? ""
              : eMailController.text.trim(),
          "phone": phoneController.text.trim(),
          "password": createPassController.text,
          "role": userrole.text,
        },
        customHeaders: {'x-otp-ticket': otpTicket},
        includeAuth: false, // Registration doesn't need auth
      );

      if (response.statusCode == 201) {
        // Clear the OTP ticket after successful registration
        await OtpService.clearSignupOtpTicket();

        // Save user role to SharedPreferences
        await SharedPrefUtils.init();
        await SharedPrefUtils.setString('user_role', userrole.text);
        log("User role saved to SharedPreferences: ${userrole.text}");

        await Future.delayed(const Duration(seconds: 1));
        clearFormFields();
        Get.toNamed(AppRoutes.login);
        return {'success': true, 'message': 'Registration successful!'};
      } else {
        // Parse error message from response
        String errorMessage = "Registration failed.";
        try {
          dynamic data = jsonDecode(response.body);
          if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } catch (e) {
          log('Error parsing response body: $e');
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Exception $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<bool> loginUser() async {
    // Basic validation - UI will handle detailed validation
    if (eMailController.text.isEmpty || confirmPassController.text.isEmpty) {
      return false;
    }

    // Validate mobile number (10 digits)
    if (!isValidPhone(eMailController.text.trim())) {
      return false;
    }

    try {
      log(
        "api/auth/login : phone=${eMailController.text.trim()}, password=***",
      );
      final response = await ApiService.post(
        '/api/auth/login',
        body: {
          "phone": eMailController.text.trim(),
          "password": confirmPassController.text.trim(),
          "role": "shopkeeper",
        },
        includeAuth: false, // Login doesn't need auth
      );
      if (response.statusCode == 200) {
        String userRole = 'user'; // Default role

        // Parse response to get user role and token
        try {
          dynamic data = jsonDecode(response.body);
          userRole =
              data['user']?['role'] ??
              'user'; // Default to 'user' if role not found

          // Extract user info
          int userId = data['user']?['id'] ?? data['id'] ?? 0;
          String username = data['user']?['username'] ?? '';
          String email = data['user']?['email'] ?? '';

          // Try all possible token field names - check the actual response structure
          String token = '';
          log('🔍 Checking token fields in response...');

          // Check for tokens in various locations
          if (data['accessToken'] != null && data['accessToken'].isNotEmpty) {
            token = data['accessToken'];
            log('✅ Found token in accessToken field');
          } else if (data['access_token'] != null &&
              data['access_token'].isNotEmpty) {
            token = data['access_token'];
            log('✅ Found token in access_token field');
          } else if (data['token'] != null && data['token'].isNotEmpty) {
            token = data['token'];
            log('✅ Found token in token field');
          } else if (data['authToken'] != null &&
              data['authToken'].isNotEmpty) {
            token = data['authToken'];
            log('✅ Found token in authToken field');
          } else if (data['auth_token'] != null &&
              data['auth_token'].isNotEmpty) {
            token = data['auth_token'];
            log('✅ Found token in auth_token field');
          } else {
            // Last resort - check all keys for token
            log(
              '⚠️ No standard token field found. Response keys: ${data.keys.toList()}',
            );
            log('⚠️ Full response: $data');
          }

          // Get refresh token if available (separate from access token)
          String refreshToken = '';
          if (data['refreshToken'] != null && data['refreshToken'].isNotEmpty) {
            refreshToken = data['refreshToken'];
            log('✅ Found refresh token in refreshToken field');
          } else if (data['refresh_token'] != null &&
              data['refresh_token'].isNotEmpty) {
            refreshToken = data['refresh_token'];
            log('✅ Found refresh token in refresh_token field');
          }

          // IMPORTANT: If backend only sends one token, use it as both access and refresh
          // This handles backends that issue a single JWT token for both purposes
          if (token.isNotEmpty && refreshToken.isEmpty) {
            // Check if this token might be a refresh token based on JWT claims
            try {
              List<String> parts = token.split('.');
              if (parts.length == 3) {
                String payload = parts[1];
                while (payload.length % 4 != 0) {
                  payload += '=';
                }
                String decodedPayload = utf8.decode(base64Decode(payload));
                Map<String, dynamic> jwtData = jsonDecode(decodedPayload);
                String tokenUse = jwtData['token_use'] ?? '';

                // If backend sends only refresh token, use it as access token too
                // (This is common for single-token backends)
                if (tokenUse == 'refresh') {
                  log(
                    '⚠️ Received only refresh token. Using as both access and refresh token.',
                  );
                  refreshToken = token;
                }
              }
            } catch (e) {
              log('⚠️ Could not analyze token_use claim');
            }
          }

          // Validate that we got a valid user ID
          if (userId <= 0) {
            log('Warning: Invalid user ID received from server: $userId');
            // Try to extract from other possible fields
            if (data['user_id'] != null) {
              userId = int.tryParse(data['user_id'].toString()) ?? 0;
            }
            if (userId <= 0) {
              log('Error: No valid user ID found in login response');
            }
          }

          // Validate token
          if (token.isEmpty) {
            log('❌ No valid access token found in login response!');
            return false;
          }

          // Debug: Log what tokens we received
          log('🔍 Login response data keys: ${data.keys.toList()}');
          log(
            '🔍 Access token: ${token.isNotEmpty ? "✅ Present (${token.length} chars)" : "❌ Missing"}',
          );
          log(
            '🔍 Refresh token: ${refreshToken.isNotEmpty ? "✅ Present (${refreshToken.length} chars)" : "⚠️ Missing"}',
          );
          log(
            '🔍 Expires in raw value: ${data['expires_in'] ?? data['expiresIn'] ?? "Not provided (using default 24h)"}',
          );

          // Decode and log JWT payload to verify it's an access token
          try {
            List<String> parts = token.split('.');
            if (parts.length == 3) {
              String payload = parts[1];
              while (payload.length % 4 != 0) {
                payload += '=';
              }
              String decodedPayload = utf8.decode(base64Decode(payload));
              Map<String, dynamic> jwtData = jsonDecode(decodedPayload);
              String tokenRole = jwtData['role'] ?? 'unknown';

              log(
                '🔍 JWT token_use: ${jwtData['token_use'] ?? "not specified"}',
              );
              log('🔍 JWT userId: ${jwtData['userId']}');
              log('🔍 JWT role: $tokenRole');

              // WARNING: Check if token role matches expected role
              if (tokenRole != userRole &&
                  tokenRole == 'user' &&
                  userRole == 'shopkeeper') {
                log(
                  '⚠️⚠️⚠️ CRITICAL: Backend issued token with role "user" but user is registered as "shopkeeper"',
                );
                log(
                  '⚠️ This will cause 401 errors when calling shopkeeper-only endpoints',
                );
                log(
                  '⚠️ Backend login endpoint must preserve the user role from registration',
                );
              }
            }
          } catch (e) {
            log('⚠️ Could not decode JWT for verification: $e');
          }

          // Store tokens using TokenManager
          await TokenManager.storeTokens(
            accessToken: token,
            refreshToken: refreshToken,
            expiresIn: data['expires_in'] ?? data['expiresIn'], // TokenManager will handle parsing
          );

          // Save user data to SharedPreferences
          await SharedPrefUtils.init();
          await SharedPrefUtils.setBool('is_logged_in', true);
          userRole = 'shopkeeper';
          await SharedPrefUtils.setString('user_role', userRole);
          await SharedPrefUtils.setString('view_mode', 'shop');
          await SharedPrefUtils.setString('user_id', userId.toString());
          await SharedPrefUtils.setString('username', username);
          await SharedPrefUtils.setString('user_email', email);
          // Persist the login phone number so it can be reused (e.g., for tickets)
          await SharedPrefUtils.setString(
            'user_phone',
            eMailController.text.trim(),
          );

          // Update global state variables using helper function
          await initializeGlobalState();

          log(
            'Login successful - Role: $userRole, UserID: $userId, Username: $username, Token: ${token.isNotEmpty ? "Present" : "Missing"}',
          );
          log(
            'Global state updated - isShopkeeper: ${isShopkeeper.value}, globalUser: ${globalUser.value}',
          );

          // Sync FCM token with backend after login so token is linked to this account.
          print('[FCM_CHECK] login success, triggering FCM backend sync');
          await FcmService.syncTokenWithBackend();

          log('');
          log('═══════════════════════════════════════════════════════════');
          log('⚠️  IMPORTANT BACKEND ISSUE DETECTED:');
          log('═══════════════════════════════════════════════════════════');
          log(
            'The /api/auth/login endpoint is issuing tokens with "role":"user"',
          );
          log('even though this account was registered as a "shopkeeper".');
          log('');
          log(
            'This causes 401 errors when accessing shopkeeper-only endpoints',
          );
          log(
            'like /api/shop/add which expect "role":"shopkeeper" in the token.',
          );
          log('');
          log('REQUIRED FIX: Backend /api/auth/login must:');
          log('1. Read the user role from the database');
          log('2. Include the correct role in the issued JWT token');
          log('3. Match the role that was set during registration');
          log('═══════════════════════════════════════════════════════════');
          log('');
        } catch (e) {
          log('Error parsing login response: $e');
          // Clear authentication data if parsing fails
          userRole = 'user';
          await TokenManager.clearTokens();
          await SharedPrefUtils.init();
          await SharedPrefUtils.setBool('is_logged_in', false);
          await SharedPrefUtils.setString('user_role', 'user');
          await SharedPrefUtils.setString('user_id', '0');

          // Reset global state variables
          resetGlobalState();
        }

        await Future.delayed(const Duration(seconds: 1));
        eMailController.clear();
        confirmPassController.clear();
        Get.offAllNamed(AppRoutes.shopkeeperHome);
        // Redirect based on user role
        // if (userRole == 'shopkeeper') {
        //   Get.offAllNamed(AppRoutes.shopkeeperHome);
        // } else {
        //   Get.offAllNamed(AppRoutes.home);
        // }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      log('Exception $e');
      // Return false for login failure - UI will handle the error message
      return false;
    }
  }

  // Forgot Password OTP Methods
  Future<Map<String, dynamic>> requestPasswordResetOtp(String phone) async {
    if (phone.isEmpty) {
      return {'success': false, 'message': 'Please enter phone number'};
    }

    if (!isValidPhone(phone.trim())) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit phone number',
      };
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.sendOtp(
        phone: phone.trim(),
        purpose:
            'reset_password', // Use reset_password purpose for password reset
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Send forgot password OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(
    String phone,
    String otp,
  ) async {
    if (phone.isEmpty) {
      return {'success': false, 'message': 'Phone number is required'};
    }

    if (otp.isEmpty) {
      return {'success': false, 'message': 'Please enter OTP'};
    }

    if (otp.length != 6) {
      return {'success': false, 'message': 'Please enter a valid 6-digit OTP'};
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.verifyOtp(
        phone: phone.trim(),
        otp: otp.trim(),
        purpose:
            'reset_password', // Use reset_password purpose for password reset
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Verify forgot password OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to verify OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<Map<String, dynamic>> resendForgotPasswordOtp(String phone) async {
    if (phone.isEmpty) {
      return {'success': false, 'message': 'Please enter phone number'};
    }

    if (!isValidPhone(phone.trim())) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit phone number',
      };
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.resendOtp(
        phone: phone.trim(),
        purpose:
            'reset_password', // Use reset_password purpose for password reset
        channel: 'sms',
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Resend forgot password OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to resend OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String phone,
    String newPassword,
  ) async {
    if (phone.isEmpty) {
      return {'success': false, 'message': 'Phone number is required'};
    }

    if (newPassword.isEmpty) {
      return {'success': false, 'message': 'Please enter new password'};
    }

    if (!isValidPassword(newPassword)) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters long',
      };
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.resetPassword(
        phone: phone.trim(),
        newPassword: newPassword,
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Reset password error: $e');
      return {
        'success': false,
        'message': 'Failed to reset password. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  // OTP Methods
  Future<Map<String, dynamic>> checkSignupPhoneAvailability(
    String phone,
  ) async {
    final trimmedPhone = phone.trim();

    if (trimmedPhone.isEmpty) {
      return {
        'success': false,
        'exists': false,
        'message': 'Please enter phone number',
      };
    }

    if (!isValidPhone(trimmedPhone)) {
      return {
        'success': false,
        'exists': false,
        'message': 'Please enter a valid 10-digit phone number',
      };
    }

    try {
      final response = await ApiService.post(
        '/api/user/check-phone',
        body: {'phone': trimmedPhone, "role": "shopkeeper"},
        includeAuth: false,
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      final message = (data['message'] ?? '').toString();

      if (response.statusCode == 200) {
        final exists =
            data['exists'] == true ||
            data['isExists'] == true ||
            data['registered'] == true ||
            data['available'] == false;

        return {
          'success': true,
          'exists': exists,
          'message': message.isNotEmpty
              ? message
              : (exists
                    ? 'This phone number is already registered.'
                    : 'Phone number is available.'),
          'data': data,
        };
      }

      final normalizedMessage = message.toLowerCase();
      final existsFromMessage =
          normalizedMessage.contains('already') ||
          normalizedMessage.contains('exist') ||
          normalizedMessage.contains('registered');

      if (response.statusCode == 409 || existsFromMessage) {
        return {
          'success': true,
          'exists': true,
          'message': message.isNotEmpty
              ? message
              : 'This phone number is already registered.',
          'data': data,
        };
      }

      if (response.statusCode == 404) {
        // Check endpoint unavailable; allow manual OTP send button flow.
        return {
          'success': true,
          'exists': false,
          'checkUnavailable': true,
          'message': '',
          'data': data,
        };
      }

      return {
        'success': false,
        'exists': false,
        'message': message.isNotEmpty
            ? message
            : 'Unable to verify phone number right now.',
        'data': data,
      };
    } catch (e) {
      log('Check phone availability error: $e');
      return {
        'success': false,
        'exists': false,
        'message': 'Failed to verify phone number. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> sendOtp() async {
    if (phoneController.text.isEmpty) {
      return {'success': false, 'message': 'Please enter phone number'};
    }

    if (!isValidPhone(phoneController.text.trim())) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit phone number',
      };
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.sendOtp(
        phone: phoneController.text.trim(),
        purpose: 'signup',
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp() async {
    if (otpController.text.isEmpty) {
      return {'success': false, 'message': 'Please enter OTP'};
    }

    if (otpController.text.length != 6) {
      return {'success': false, 'message': 'Please enter a valid 6-digit OTP'};
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.verifyOtp(
        phone: phoneController.text.trim(),
        otp: otpController.text.trim(),
        purpose: 'signup',
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to verify OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }

  Future<Map<String, dynamic>> resendOtp() async {
    if (phoneController.text.isEmpty) {
      return {'success': false, 'message': 'Please enter phone number'};
    }

    if (!isValidPhone(phoneController.text.trim())) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit phone number',
      };
    }

    isUploadingData.value = true;

    try {
      final result = await OtpService.resendOtp(
        phone: phoneController.text.trim(),
        purpose: 'signup',
        channel: 'sms',
        role: 'shopkeeper',
      );

      return result;
    } catch (e) {
      log('Resend OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to resend OTP. Please try again.',
      };
    } finally {
      isUploadingData.value = false;
    }
  }
}
