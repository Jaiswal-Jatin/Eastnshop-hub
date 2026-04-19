import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../Routes/App_Pages.dart';
import 'SharedPrefUtils.dart';
import 'TokenManager.dart';

class ApiService {
  static const String _baseUrl = AppRoutes.domainName;

  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      // Get valid access token (automatically refresh if needed)
      String? token = await TokenManager.getValidAccessToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        log('🔐 API Request with token: ${token.substring(0, 20)}...');
      } else {
        log('⚠️ No valid auth token found for API request');
      }
    }

    return headers;
  }

  // GET request
  static Future<http.Response> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 GET Request: $url');
      log('📋 Headers: $headers');

      final response = await http.get(url, headers: headers);

      log('📥 GET Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ GET Request Error: $e');
      rethrow;
    }
  }

  // POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 POST Request: $url');
      log('📋 Headers: $headers');
      log('📤 Body: ${body != null ? jsonEncode(body) : 'null'}');

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 POST Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ POST Request Error: $e');
      rethrow;
    }
  }

  // POST request with custom headers
  static Future<http.Response> postWithCustomHeaders(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);

      // Add custom headers if provided
      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 POST Request with Custom Headers: $url');
      log('📋 Headers: $headers');
      log('📤 Body: ${body != null ? jsonEncode(body) : 'null'}');

      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 POST Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ POST Request with Custom Headers Error: $e');
      rethrow;
    }
  }

  // PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 PUT Request: $url');
      log('📋 Headers: $headers');
      log('📤 Body: ${body != null ? jsonEncode(body) : 'null'}');

      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 PUT Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ PUT Request Error: $e');
      rethrow;
    }
  }

  // PATCH request
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 PATCH Request: $url');
      log('📋 Headers: $headers');

      if (body != null) {
        log('📤 Body: $body');
        headers['Content-Type'] = 'application/json';
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 PATCH Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ PATCH Request Error: $e');
      rethrow;
    }
  }

  // DELETE request
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('$_baseUrl$endpoint');

      log('🌐 DELETE Request: $url');
      log('📋 Headers: $headers');
      log('📤 Body: ${body != null ? jsonEncode(body) : 'null'}');

      final response = await http.delete(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      log('📥 DELETE Response: ${response.statusCode} - ${response.body}');

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ DELETE Request Error: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await TokenManager.isAuthenticated();
  }

  // Get current user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    await SharedPrefUtils.init();

    String? userId = SharedPrefUtils.getString('user_id');
    String? userRole = SharedPrefUtils.getString('user_role');
    String? username = SharedPrefUtils.getString('username');
    String? token = SharedPrefUtils.getString('auth_token');

    if (userId != null && userRole != null && token != null) {
      return {
        'id': int.tryParse(userId) ?? 0,
        'role': userRole,
        'username': username ?? '',
        'token': token,
      };
    }

    return null;
  }

  // Clear authentication data
  static Future<void> clearAuth() async {
    await TokenManager.clearTokens();
    await SharedPrefUtils.init();
    await SharedPrefUtils.remove('user_id');
    await SharedPrefUtils.remove('user_role');
    await SharedPrefUtils.remove('username');
    await SharedPrefUtils.remove('user_email');
    await SharedPrefUtils.remove('user_phone');
    log('🧹 Authentication data cleared');
  }

  // Handle API response and check for authentication errors
  static Future<bool> handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      log('🔒 Unauthorized access - token may be expired');

      // Try to refresh token first
      int refreshResult = await TokenManager.refreshAccessToken();

      if (refreshResult == TokenManager.refreshAuthFailure) {
        // If refresh fails due to invalid/expired refresh token, clear tokens
        log('🔄 Token refresh failed (Auth Error) - clearing tokens');
        await TokenManager.clearTokens();
        return false;
      } else if (refreshResult == TokenManager.refreshTransientFailure) {
        // If refresh fails due to network/server error, don't clear tokens
        log('⚠️ Token refresh transient failure - NOT clearing tokens');
        return false;
      }

      // Token refreshed successfully (refreshResult == TokenManager.refreshSuccess)
      log('✅ Token refreshed successfully - request should be retried');
      return false;
    }
    return true;
  }

  // Get content type from file extension
  static String _getContentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // default fallback
    }
  }

  // POST request with multipart form data for file uploads
  static Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add headers (without Content-Type for multipart)
      Map<String, String> headers = {'Accept': 'application/json'};

      if (includeAuth) {
        // Get valid access token (automatically refresh if needed)
        String? token = await TokenManager.getValidAccessToken();

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          log(
            '🔐 Multipart API Request with token: ${token.substring(0, 20)}...',
          );
        } else {
          log('⚠️ No valid auth token found for multipart API request');
        }
      }

      request.headers.addAll(headers);

      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files - handle multiple files with the same field name
      if (files != null) {
        // Group files by field name to handle multiple files with same field name
        Map<String, List<File>> groupedFiles = {};
        for (String key in files.keys) {
          // Extract base field name (e.g., 'photos' from 'photos_0', 'photos_1', etc.)
          String baseFieldName = key;
          if (key.contains('_')) {
            baseFieldName = key.substring(0, key.lastIndexOf('_'));
          }

          if (!groupedFiles.containsKey(baseFieldName)) {
            groupedFiles[baseFieldName] = [];
          }
          groupedFiles[baseFieldName]!.add(files[key]!);
        }

        // Add all files to the request
        for (String fieldName in groupedFiles.keys) {
          List<File> fieldFiles = groupedFiles[fieldName]!;
          log(
            '📁 Grouping ${fieldFiles.length} files under field name: $fieldName',
          );
          for (File file in fieldFiles) {
            log('📁 Adding file: $fieldName -> ${file.path}');
            log('📁 File exists: ${await file.exists()}');
            log('📁 File size: ${await file.length()} bytes');

            // Get file extension and log it
            String fileName = file.path.split('/').last.toLowerCase();
            String extension = fileName.split('.').last;
            log('📁 File name: $fileName, extension: $extension');

            // Create multipart file with explicit content type
            String contentType = _getContentTypeFromExtension(extension);
            log('📁 Content type: $contentType');

            // Read file bytes to ensure we have the actual content
            List<int> fileBytes = await file.readAsBytes();
            log('📁 File bytes length: ${fileBytes.length}');

            // Create multipart file from bytes with explicit content type
            request.files.add(
              http.MultipartFile.fromBytes(
                fieldName,
                fileBytes,
                filename: fileName,
                contentType: MediaType.parse(contentType),
              ),
            );
          }
        }
      }

      log('🌐 Multipart POST Request: $url');
      log('📋 Headers: ${request.headers}');
      log('📤 Fields: ${request.fields}');
      log('📁 Files: ${files?.keys.toList()}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log(
        '📥 Multipart POST Response: ${response.statusCode} - ${response.body}',
      );

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ Multipart POST Request Error: $e');
      rethrow;
    }
  }

  // PUT request with multipart form data for file uploads
  static Future<http.Response> putMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');

      // Create multipart request
      var request = http.MultipartRequest('PUT', url);

      // Add headers (without Content-Type for multipart)
      Map<String, String> headers = {'Accept': 'application/json'};

      if (includeAuth) {
        // Get valid access token (automatically refresh if needed)
        String? token = await TokenManager.getValidAccessToken();

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          log(
            '🔐 Multipart PUT API Request with token: ${token.substring(0, 20)}...',
          );
        } else {
          log('⚠️ No valid auth token found for multipart PUT API request');
        }
      }

      request.headers.addAll(headers);

      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files - handle multiple files with the same field name
      if (files != null) {
        // Group files by field name to handle multiple files with same field name
        Map<String, List<File>> filesByField = {};
        for (String key in files.keys) {
          // Extract base field name (e.g., 'photos' from 'photos_0', 'photos_1', etc.)
          String baseFieldName = key;
          if (key.contains('_')) {
            baseFieldName = key.substring(0, key.lastIndexOf('_'));
          }

          if (!filesByField.containsKey(baseFieldName)) {
            filesByField[baseFieldName] = [];
          }
          filesByField[baseFieldName]!.add(files[key]!);
        }

        for (String fieldName in filesByField.keys) {
          List<File> fieldFiles = filesByField[fieldName]!;
          log(
            '📁 Grouping ${fieldFiles.length} files under field name: $fieldName',
          );

          for (File file in fieldFiles) {
            log('📁 Adding file: $fieldName -> ${file.path}');
            log('📁 File exists: ${await file.exists()}');
            log('📁 File size: ${await file.length()} bytes');

            // Get file extension and log it
            String fileName = file.path.split('/').last.toLowerCase();
            String extension = fileName.split('.').last;
            log('📁 File name: $fileName, extension: $extension');

            // Create multipart file with explicit content type
            String contentType = _getContentTypeFromExtension(extension);
            log('📁 Content type: $contentType');

            // Read file bytes to ensure we have the actual content
            List<int> fileBytes = await file.readAsBytes();
            log('📁 File bytes length: ${fileBytes.length}');

            // Create multipart file from bytes with explicit content type
            request.files.add(
              http.MultipartFile.fromBytes(
                fieldName,
                fileBytes,
                filename: fileName,
                contentType: MediaType.parse(contentType),
              ),
            );
          }
        }
      }

      log('🌐 Multipart PUT Request: $url');
      log('📋 Headers: ${request.headers}');
      log('📤 Fields: ${request.fields}');
      log('📁 Files: ${files?.keys.toList()}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log(
        '📥 Multipart PUT Response: ${response.statusCode} - ${response.body}',
      );

      // Handle authentication errors
      await handleResponse(response);

      return response;
    } catch (e) {
      log('❌ Multipart PUT Request Error: $e');
      rethrow;
    } 
  }

  // Subscribe to a plan
  static Future<Map<String, dynamic>> subscribeToPlan(String plan) async {
    try {
      await SharedPrefUtils.init();
      final String? userId = SharedPrefUtils.getString('user_id');

      if (userId == null || userId.isEmpty) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final Map<String, dynamic> requestBody = {
        'plan': plan.replaceAll("'", ""), // Remove quotes from plan name
        'userId': userId,
        // Add compatibility for extra plan
        if (plan == '1offer') ...{
          'plan_type': 'extra',
          'ads_count': 1,
          'description': 'Extra single ad purchase',
        }
      };

      log('📋 Subscription Request: $requestBody');
      print('DEBUG: ApiService.subscribeToPlan requestBody: $requestBody');
      print('DEBUG: ApiService.subscribeToPlan endpoint: /api/subscription/subscribe');

      // Make API call
      final response = await post(
        '/api/subscription/subscribe',
        body: requestBody,
        includeAuth: true,
      );
      
      print('DEBUG: ApiService.subscribeToPlan response status: ${response.statusCode}');
      print('DEBUG: ApiService.subscribeToPlan response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        log('✅ Subscription successful: $responseData');
        return {
          'success': true,
          'data': responseData,
          'plan': responseData['plan'],
          'price': responseData['price'],
          'days': responseData['days'],
          'adsLimit': responseData['adsLimit'],
          'message': responseData['message'] ?? 'Proceed to payment',
        };
      } else {
        String errorMessage = 'Subscription failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Server error occurred';
        }
        log('❌ Subscription failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Subscription Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create a Razorpay payment order
  static Future<Map<String, dynamic>> createPaymentOrder(String plan) async {
    try {
      await SharedPrefUtils.init();
      final String? userId = SharedPrefUtils.getString('user_id');

      if (userId == null || userId.isEmpty) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      log('📋 Creating payment order for plan: $plan');
      print('DEBUG: ApiService.createPaymentOrder plan: $plan');

      final response = await post(
        '/api/payment/create-order',
        body: {
          'plan': plan.replaceAll("'", ""),
          'userId': userId,
        },
        includeAuth: true,
      );
      
      print('DEBUG: ApiService.createPaymentOrder response status: ${response.statusCode}');
      print('DEBUG: ApiService.createPaymentOrder response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        log('✅ Payment order created: $responseData');
        return {
          'success': true,
          'orderId': responseData['orderId'],
          'amount': responseData['amount'],
          'keyId':
              responseData['keyId'] ??
              responseData['key'] ??
              responseData['razorpayKeyId'],
          'currency': responseData['currency'] ?? 'INR',
        };
      } else {
        final errorData = jsonDecode(response.body);
        log(
          '❌ Payment order creation failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to create payment order',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Create Payment Order Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify Razorpay payment
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int userId,
    required String plan,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        // Canonical keys
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,

        // Compatibility aliases
        'orderId': razorpayOrderId,
        'paymentId': razorpayPaymentId,
        'signature': razorpaySignature,
        'order_id': razorpayOrderId,
        'payment_id': razorpayPaymentId,

        // User/plan aliases
        'userId': userId,
        'user_id': userId,
        'plan': plan.replaceAll("'", ""), // Remove quotes from plan name
      };

      log('📋 Verifying payment payload: $requestBody');

      final response = await post(
        '/api/payment/verify-payment',
        body: requestBody,
        includeAuth: true,
      );

      Map<String, dynamic> responseData = {};
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else {
          responseData = {'raw': decoded};
        }
      } catch (_) {
        responseData = {'raw': response.body};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = responseData['success'] != false;
        log('${isSuccess ? '✅' : '❌'} Payment verify response: $responseData');
        return {
          'success': isSuccess,
          'message':
              responseData['message'] ??
              (isSuccess
                  ? 'Payment verified successfully'
                  : 'Payment verification failed'),
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        log(
          '❌ Payment verification failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'error':
              responseData['message'] ??
              responseData['error'] ??
              'Payment verification failed',
          'statusCode': response.statusCode,
          'data': responseData,
          'rawBody': response.body,
        };
      }
    } catch (e) {
      log('❌ Verify Payment Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create offer
  static Future<Map<String, dynamic>> createOffer({
    required int shopId,
    required String offerType,
    required double productPrice,
    required double offerPrice,
    required String productName,
    required String productBrand,
    required String offerDesign,
    required String offerDescription,
    List<File>? imageFiles,
    String? photoUrl,
  }) async {
    try {
      // Use multipart form data for file uploads (backend supports this)
      if (imageFiles != null && imageFiles.isNotEmpty) {
        log(
          '📋 Creating offer with ${imageFiles.length} images using multipart',
        );

        // Prepare form fields
        Map<String, String> fields = {
          'shop_id': shopId.toString(),
          'offer_type': offerType,
          'product_price': productPrice.toString(),
          'offer_price': offerPrice.toString(),
          'product_name': productName,
          'product_brand': productBrand,
          'offer_design': offerDesign,
          'offer_description': offerDescription,
        };

        // Prepare files map - use unique keys for each file, multipart method will group them
        Map<String, File> files = {};
        for (int i = 0; i < imageFiles.length; i++) {
          files['photos_$i'] =
              imageFiles[i]; // Use unique keys, will be grouped as 'photos'
        }

        log('📋 Offer Creation Request (Multipart): $fields');
        log('📁 Files: ${files.keys.toList()}');

        // Make multipart API call
        final response = await postMultipart(
          '/api/offer/add',
          fields: fields,
          files: files,
        );

        return _handleOfferResponse(response);
      } else {
        // Use regular JSON request for offers without images
        Map<String, dynamic> requestBody = {
          'shop_id': shopId,
          'offer_type': offerType,
          'product_price': productPrice,
          'offer_price': offerPrice,
          'product_name': productName,
          'product_brand': productBrand,
          'offer_design': offerDesign,
          'offer_description': offerDescription,
        };

        // Add photo_url if provided
        if (photoUrl != null && photoUrl.isNotEmpty) {
          requestBody['photo_url'] = photoUrl;
        }

        log('📋 Offer Creation Request (JSON): $requestBody');

        // Make API call
        final response = await post(
          '/api/offer/add',
          body: requestBody,
          includeAuth: true,
        );

        return _handleOfferResponse(response);
      }
    } catch (e) {
      log('❌ Offer creation error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Helper method to handle offer response
  static Map<String, dynamic> _handleOfferResponse(http.Response response) {
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        log('✅ Offer created successfully: $responseData');
        return {
          'success': true,
          'data': responseData,
          'message': 'Offer created successfully',
        };
      } else if (response.statusCode == 402) {
        // Handle 402 - Subscription expired
        final errorData = jsonDecode(response.body);
        log('❌ Offer creation failed - Subscription expired: ${response.body}');
        return {
          'success': false,
          'error':
              errorData['error'] ?? 'No active subscription. Please subscribe.',
          'statusCode': response.statusCode,
          'isSubscriptionExpired': true,
        };
      } else if (response.statusCode == 403) {
        // Handle 403 - Ad limit reached
        final errorData = jsonDecode(response.body);
        log('❌ Offer creation failed - Ad limit reached: ${response.body}');
        return {
          'success': false,
          'error': errorData['error'] ?? 'Ad limit reached for current plan.',
          'statusCode': response.statusCode,
          'isAdLimitReached': true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        log(
          '❌ Offer creation failed: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'error':
              errorData['message'] ??
              'Failed to create offer. Please try again.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Error parsing offer response: $e');
      return {'success': false, 'error': 'Error parsing response: $e'};
    }
  }

  // Get subscription details
  static Future<Map<String, dynamic>> getSubscriptionDetails(int userId) async {
    try {
      log('📋 Fetching subscription details for user: $userId');

      // Make API call
      final response = await get(
        '/api/subscription/me/$userId',
        includeAuth: true,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log('✅ Subscription details fetched successfully: $responseData');
        return {
          'success': true,
          'data': responseData,
          'message': 'Subscription details fetched successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        log(
          '❌ Failed to fetch subscription details: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'error':
              errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch subscription details',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Subscription Details Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Edit offer
  static Future<Map<String, dynamic>> editOffer({
    required int offerId,
    required int shopId,
    required String offerType,
    required double productPrice,
    required double offerPrice,
    required String productName,
    required String productBrand,
    required String offerDesign,
    required String offerDescription,
    List<File>? imageFiles,
    String? photoUrl,
  }) async {
    try {
      // Use multipart form data for editing offers (as shown in API image)
      if (imageFiles != null && imageFiles.isNotEmpty) {
        log(
          '📋 Editing offer with ${imageFiles.length} images using multipart form-data',
        );

        // Prepare form fields (matching the API image structure)
        Map<String, String> fields = {
          'shop_id': shopId.toString(),
          'offer_type': offerType,
          'product_price': productPrice.toString(),
          'offer_price': offerPrice.toString(),
          'product_name': productName,
          'product_brand': productBrand,
          'offer_design': offerDesign,
          'offer_description': offerDescription,
        };

        // Prepare files map - use unique keys for each file, multipart method will group them
        Map<String, File> files = {};
        for (int i = 0; i < imageFiles.length; i++) {
          files['photos_$i'] =
              imageFiles[i]; // Use unique keys, will be grouped as 'photos'
        }

        log('📋 Offer Edit Request (Multipart): $fields');
        log('📁 Files: ${files.keys.toList()}');
        log('🔍 Product Brand Value: "$productBrand"');
        log('🔍 Product Brand Length: ${productBrand.length}');

        // Make multipart PUT API call
        final response = await putMultipart(
          '/api/offer/edit/$offerId',
          fields: fields,
          files: files,
        );

        log('📋 Offer Edit Response (Multipart):');
        log('Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');

        return _handleOfferResponse(response);
      } else {
        log('📋 Editing offer without images using JSON');

        // Use regular JSON API call for editing offers without images
        Map<String, dynamic> body = {
          'shop_id': shopId,
          'offer_type': offerType,
          'product_price': productPrice,
          'offer_price': offerPrice,
          'product_name': productName,
          'product_brand': productBrand,
          'offer_design': offerDesign,
          'offer_description': offerDescription,
        };

        if (photoUrl != null && photoUrl.isNotEmpty) {
          body['photo_url'] = photoUrl;
        }

        log('📋 Offer Edit Request (JSON): $body');
        log('🔍 Product Brand Value: "$productBrand"');
        log('🔍 Product Brand Length: ${productBrand.length}');

        final response = await put('/api/offer/edit/$offerId', body: body);

        log('📋 Offer Edit Response (JSON):');
        log('Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');

        return _handleOfferResponse(response);
      }
    } catch (e) {
      log('❌ Error editing offer: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get media images for carousel
  static Future<List<Map<String, dynamic>>> getMediaImages() async {
    try {
      log('📋 Fetching media images from API');

      final response = await get('/api/media/minimal/shopkeeper');

      log('📋 Media Images Response:');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('✅ Media images fetched successfully! Count: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        log('❌ Failed to fetch media images: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('❌ Error fetching media images: $e');
      return [];
    }
  }

  // Get carousel images for user home page
  static Future<List<Map<String, dynamic>>> getCarouselImages() async {
    try {
      log('📋 Fetching carousel images from API');

      final response = await get(
        '/api/media/minimal/user/carousel',
        includeAuth: false,
      );

      log('📋 Carousel Images Response:');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('✅ Carousel images fetched successfully! Count: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        log('❌ Failed to fetch carousel images: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('❌ Error fetching carousel images: $e');
      return [];
    }
  }

  // Get image-1 for middle banner
  static Future<Map<String, dynamic>?> getImage1() async {
    try {
      log('📋 Fetching image-1 from API');

      final response = await get(
        '/api/media/minimal/user/image-1',
        includeAuth: false,
      );

      log('📋 Image-1 Response:');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          log('✅ Image-1 fetched successfully!');
          return data.first as Map<String, dynamic>;
        } else {
          log('❌ No image-1 data found');
          return null;
        }
      } else {
        log('❌ Failed to fetch image-1: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching image-1: $e');
      return null;
    }
  }

  // Get image-2 for bottom banner
  static Future<Map<String, dynamic>?> getImage2() async {
    try {
      log('📋 Fetching image-2 from API');

      final response = await get(
        '/api/media/minimal/user/image-2',
        includeAuth: false,
      );

      log('📋 Image-2 Response:');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          log('✅ Image-2 fetched successfully!');
          return data.first as Map<String, dynamic>;
        } else {
          log('❌ No image-2 data found');
          return null;
        }
      } else {
        log('❌ Failed to fetch image-2: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching image-2: $e');
      return null;
    }
  }

  // Upload single image
  static Future<String?> uploadImage(File imageFile) async {
    try {
      log('📁 Uploading single image: ${imageFile.path}');

      // Check if file exists
      if (!await imageFile.exists()) {
        log('❌ Image file does not exist: ${imageFile.path}');
        return null;
      }

      // Get file size
      int fileSize = await imageFile.length();
      log('📁 File size: $fileSize bytes');

      // Prepare files map
      Map<String, File> files = {'photo': imageFile};

      log('📁 Uploading image file: ${imageFile.path}');

      // Make multipart API call to upload endpoint
      final response = await postMultipart(
        '/api/upload/image',
        fields: {},
        files: files,
      );

      log('📁 Image Upload Response:');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          dynamic data = jsonDecode(response.body);
          String? imageUrl = data['url'] ?? data['path'] ?? data['imageUrl'];
          if (imageUrl != null) {
            log('✅ Image uploaded successfully: $imageUrl');
            return imageUrl;
          } else {
            log('❌ No image URL in response');
            return null;
          }
        } catch (e) {
          log('⚠️ Could not parse response JSON: $e');
          return null;
        }
      } else {
        log('❌ Image upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
      return null;
    }
  }

  // Get all subscription plans
  static Future<Map<String, dynamic>> getPlans() async {
    try {
      log('📋 Fetching subscription plans');
      
      final response = await get('/api/plans', includeAuth: false);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('✅ Plans fetched successfully: ${data.length} plans');
        return {
          'success': true,
          'data': data,
        };
      } else {
        log('❌ Failed to fetch plans: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch plans',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Get Plans Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get additional subscription plans for active subscribers
  static Future<Map<String, dynamic>> getAdditionalPlans() async {
    try {
      log('📋 Fetching additional subscription plans');
      
      final response = await get('/api/plans/additional', includeAuth: true);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('✅ Additional plans fetched successfully: ${data.length} plans');
        return {
          'success': true,
          'data': data,
        };
      } else {
        log('❌ Failed to fetch additional plans: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch additional plans',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      log('❌ Get Additional Plans Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

  
