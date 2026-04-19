import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';

class OtpService {
  // Send OTP
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String? purpose,
    String? role,
  }) async {
    try {
      log('📱 Sending OTP to: $phone, purpose: $purpose, role: $role');

      Map<String, dynamic> body = {'phone': phone};
      if (purpose != null) {
        body['purpose'] = purpose;
      }
      if (role != null) {
        body['role'] = role;
      }

      final response = await ApiService.post(
        '/api/otp/send',
        body: body,
        includeAuth: false, // OTP endpoints don't require authentication
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ OTP sent successfully: $data');
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'data': data,
        };
      } else {
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'message': 'Server error occurred'};
        }

        log('❌ OTP send failed: ${response.statusCode} - ${response.body}');

        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                errorData['message'] ??
                'Invalid request. Please check your mobile number.';
            break;
          case 401:
            errorMessage = 'Unauthorized request. Please try again.';
            break;
          case 429:
            errorMessage =
                'Too many requests. Please wait before trying again.';
            break;
          case 500:
            errorMessage =
                'Server error. Please try again later or contact support.';
            break;
          case 503:
            errorMessage =
                'Service temporarily unavailable. Please try again later.';
            break;
          default:
            errorMessage =
                errorData['message'] ?? 'Failed to send OTP. Please try again.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ OTP send error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? purpose,
    String? role,
  }) async {
    try {
      log('🔍 Verifying OTP: $otp for phone: $phone, purpose: $purpose, role: $role');

      Map<String, dynamic> body = {'phone': phone, 'otp': otp};
      if (purpose != null) {
        body['purpose'] = purpose;
      }
      if (role != null) {
        body['role'] = role;
      }

      final response = await ApiService.post(
        '/api/otp/verify',
        body: body,
        includeAuth: false, // OTP endpoints don't require authentication
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ OTP verified successfully: $data');

        // Store OTP ticket if it exists (server returns 'otp_ticket' for signup)
        final ticket = data['otp_ticket'] ?? data['ticket'];
        if (ticket != null) {
          if (purpose == 'signup') {
            await storeSignupOtpTicket(ticket);
          } else {
            await _storeResetToken(ticket);
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified successfully',
          'data': data,
        };
      } else {
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'message': 'Server error occurred'};
        }

        log(
          '❌ OTP verification failed: ${response.statusCode} - ${response.body}',
        );

        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                errorData['message'] ??
                'Invalid OTP. Please check and try again.';
            break;
          case 401:
            errorMessage = 'Unauthorized request. Please try again.';
            break;
          case 404:
            errorMessage =
                'OTP not found or expired. Please request a new OTP.';
            break;
          case 429:
            errorMessage =
                'Too many attempts. Please wait before trying again.';
            break;
          case 500:
            errorMessage =
                'Server error. Please try again later or contact support.';
            break;
          default:
            errorMessage =
                errorData['message'] ?? 'Invalid OTP. Please try again.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ OTP verification error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String phone,
    required String purpose,
    String channel = 'sms',
    String? role,
  }) async {
    try {
      log('🔄 Resending OTP to: $phone via $channel, purpose: $purpose, role: $role');

      final response = await ApiService.post(
        '/api/otp/resend',
        body: {
          'phone': phone,
          'purpose': purpose,
          'channel': channel,
          if (role != null) 'role': role,
        },
        includeAuth: false, // OTP endpoints don't require authentication
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ OTP resent successfully: $data');
        return {
          'success': true,
          'message': data['message'] ?? 'OTP resent successfully',
          'data': data,
        };
      } else {
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'message': 'Server error occurred'};
        }

        log('❌ OTP resend failed: ${response.statusCode} - ${response.body}');

        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                errorData['message'] ??
                'Invalid request. Please check your mobile number.';
            break;
          case 401:
            errorMessage = 'Unauthorized request. Please try again.';
            break;
          case 429:
            errorMessage =
                'Too many requests. Please wait before trying again.';
            break;
          case 500:
            errorMessage =
                'Server error. Please try again later or contact support.';
            break;
          case 503:
            errorMessage =
                'Service temporarily unavailable. Please try again later.';
            break;
          default:
            errorMessage =
                errorData['message'] ??
                'Failed to resend OTP. Please try again.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ OTP resend error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // Reset Password using OTP token
  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String newPassword,
    String? role,
  }) async {
    try {
      log('🔐 Resetting password for phone: $phone, role: $role');

      // Get stored reset token
      final resetToken = await _getResetToken();
      if (resetToken == null) {
        return {
          'success': false,
          'message': 'No valid reset token found. Please verify OTP again.',
        };
      }

      final response = await _makeCustomPostRequest(
        '/api/password/reset-password',
        body: {
          'phone': phone,
          'newPassword': newPassword,
          if (role != null) 'role': role,
        },
        customHeaders: {'x-otp-ticket': resetToken},
      );

      if (response.statusCode == 200) {
        log('✅ Password reset successfully: ${response.body}');

        // Clear the reset token after successful password reset
        await _clearResetToken();

        // Handle both JSON and plain text responses
        String message = 'Password reset successfully';
        Map<String, dynamic>? data;

        try {
          // Try to parse as JSON first
          data = jsonDecode(response.body);
          message = data?['message'] ?? response.body;
        } catch (e) {
          // If JSON parsing fails, use the plain text response
          message = response.body.isNotEmpty ? response.body : message;
          log('📝 Using plain text response: $message');
        }

        return {'success': true, 'message': message, 'data': data};
      } else {
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          // Handle plain text error responses
          errorData = {
            'message': response.body.isNotEmpty
                ? response.body
                : 'Server error occurred',
          };
        }

        log(
          '❌ Password reset failed: ${response.statusCode} - ${response.body}',
        );

        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                errorData['message'] ??
                'Invalid request. Please check your details.';
            break;
          case 401:
            errorMessage =
                'Invalid or expired reset token. Please verify OTP again.';
            break;
          case 404:
            errorMessage = 'User not found. Please check your phone number.';
            break;
          case 500:
            errorMessage =
                'Server error. Please try again later or contact support.';
            break;
          default:
            errorMessage =
                errorData['message'] ??
                'Failed to reset password. Please try again.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Password reset error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  // Custom POST request with custom headers
  static Future<http.Response> _makeCustomPostRequest(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = Uri.parse('${AppRoutes.domainName}$endpoint');

      // Prepare headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add custom headers if provided
      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      log('🌐 Custom POST Request: $url');
      log('📋 Headers: $headers');
      log('📤 Body: ${body != null ? jsonEncode(body) : 'null'}');

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 Custom POST Response: ${response.statusCode} - ${response.body}');

      return response;
    } catch (e) {
      log('❌ Custom POST Request Error: $e');
      rethrow;
    }
  }

  // Helper method to store reset token
  static Future<void> _storeResetToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reset_otp_token', token);
      log('🔑 Reset token stored successfully');
    } catch (e) {
      log('❌ Failed to store reset token: $e');
    }
  }

  // Helper method to get reset token
  static Future<String?> _getResetToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('reset_otp_token');
    } catch (e) {
      log('❌ Failed to get reset token: $e');
      return null;
    }
  }

  // Helper method to clear reset token
  static Future<void> _clearResetToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reset_otp_token');
      log('🔑 Reset token cleared successfully');
    } catch (e) {
      log('❌ Failed to clear reset token: $e');
    }
  }

  // Helper method to store signup OTP ticket
  static Future<void> storeSignupOtpTicket(String ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signup_otp_ticket', ticket);
      log(
        '🎫 Signup OTP ticket stored successfully: ${ticket.substring(0, 20)}...',
      );

      // Verify it was stored
      final stored = prefs.getString('signup_otp_ticket');
      if (stored != null) {
        log('✅ Verification: Ticket confirmed in SharedPreferences');
      } else {
        log(
          '❌ Verification failed: Ticket not found in SharedPreferences after storing!',
        );
      }
    } catch (e) {
      log('❌ Failed to store signup OTP ticket: $e');
    }
  }

  // Helper method to get signup OTP ticket
  static Future<String?> getSignupOtpTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticket = prefs.getString('signup_otp_ticket');
      if (ticket != null) {
        log('✅ Retrieved signup OTP ticket: ${ticket.substring(0, 20)}...');
      } else {
        log('❌ Signup OTP ticket not found in SharedPreferences');
        // Debug: List all keys in SharedPreferences
        final allKeys = prefs.getKeys();
        log('📋 Available keys in SharedPreferences: $allKeys');
      }
      return ticket;
    } catch (e) {
      log('❌ Failed to get signup OTP ticket: $e');
      return null;
    }
  }

  // Helper method to clear signup OTP ticket
  static Future<void> clearSignupOtpTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('signup_otp_ticket');
      log('🎫 Signup OTP ticket cleared successfully');
    } catch (e) {
      log('❌ Failed to clear signup OTP ticket: $e');
    }
  }

  // Test API connectivity
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    try {
      log('🔍 Testing API connectivity...');

      final response = await ApiService.get(
        '/api/health', // Assuming there's a health endpoint
        includeAuth: false,
      );

      log('✅ API connectivity test: ${response.statusCode} - ${response.body}');
      return {
        'success': true,
        'message': 'API is reachable',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      log('❌ API connectivity test failed: $e');
      return {
        'success': false,
        'message': 'API is not reachable: $e',
        'error': e.toString(),
      };
    }
  }
}
