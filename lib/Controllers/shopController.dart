import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Models/ShopModel.dart';
import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';
import '../Utils/SharedPrefUtils.dart';

class ShopController extends GetxController {
  TextEditingController shopNameController = TextEditingController();
  TextEditingController ownerNameController = TextEditingController();
  TextEditingController shopTypeController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController shopAddressController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController photoUrlController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();



  // Helper method to format time range from 24-hour to 12-hour format
  String _formatTimeRange(String openTime, String closeTime) {
    try {
      // Parse open time (format: "09:00:00")
      List<String> openParts = openTime.split(':');
      int openHour = int.parse(openParts[0]);
      int openMinute = int.parse(openParts[1]);

      // Parse close time (format: "18:00:00")
      List<String> closeParts = closeTime.split(':');
      int closeHour = int.parse(closeParts[0]);
      int closeMinute = int.parse(closeParts[1]);

      // Format open time
      String openFormatted = _formatTime(openHour, openMinute);

      // Format close time
      String closeFormatted = _formatTime(closeHour, closeMinute);

      return "$openFormatted - $closeFormatted";
    } catch (e) {
      log("Error formatting time range: $e");
      return "09:00 AM - 06:00 PM"; // Default fallback
    }
  }

  // Helper method to format individual time
  String _formatTime(int hour, int minute) {
    String period = hour >= 12 ? "PM" : "AM";
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$displayHour:$minuteStr $period";
  }

  // Method to convert image to base64 with size limit
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      log("Converting image to base64: ${imageFile.path}");

      // Read the image file as bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Check original file size (limit to 1MB)
      if (imageBytes.length > 1024 * 1024) {
        log("Image file too large: ${imageBytes.length} bytes (max 1MB)");
        return null;
      }

      // Convert to base64
      String base64Image = base64Encode(imageBytes);

      // Check base64 size (limit to 700KB in base64)
      if (base64Image.length > 700000) {
        log(
          "Base64 image too large: ${base64Image.length} characters (max 700KB)",
        );
        return null;
      }

      // Get file extension
      String extension = imageFile.path.split('.').last.toLowerCase();

      // Create data URL format
      String dataUrl = 'data:image/$extension;base64,$base64Image';

      log(
        "Image converted to base64 successfully. Size: ${base64Image.length} characters",
      );
      return dataUrl;
    } catch (e) {
      log("Error converting image to base64: $e");
      return null;
    }
  }

  // Method to upload image to server (keeping for future server upload)
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Convert to base64 for now
      String? base64Image = await convertImageToBase64(imageFile);
      return base64Image;
    } catch (e) {
      log("Error uploading image: $e");
      return null;
    }
  }

  Future<bool> addShop({
    required String shopName,
    required String ownerName,
    required String shopType,
    required String pinCode,
    required String shopAddress,
    required String location,
    required String contactNumber,
    required File? imageFile,
    required int userId,
    Map<String, List<Map<String, String>>>? workingHours,
  }) async {
    // ✅ Basic validation
    if (shopName.isEmpty ||
        ownerName.isEmpty ||
        shopType.isEmpty ||
        pinCode.isEmpty ||
        shopAddress.isEmpty ||
        location.isEmpty ||
        contactNumber.isEmpty ||
        userId <= 0) {
      log(
        "❌ Validation failed: One or more required fields are empty or userId is invalid ($userId)",
      );
      return false;
    }

    try {
      // Prepare form fields with null safety - matching Postman API spec
      Map<String, String> fields = {
        "shop_name": shopName.trim(),
        "owner_name": ownerName.trim(),
        "number": contactNumber.trim(),
        "shop_type": shopType.trim(),
        "pin_code": pinCode.trim(),
        "shop_address": shopAddress.trim(),
        "location": location.trim(),
        "user_id": userId.toString(), // Added user_id to form fields
      };

      // Add working hours if provided - matching new API spec
      if (workingHours != null && workingHours.isNotEmpty) {
        // Create a granular list of working hours (one object per day)
        List<Map<String, dynamic>> workingHoursList = [];

        // Sort days for consistency
        List<String> sortedDays = workingHours.keys.toList()
          ..sort((a, b) {
            const daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return daysOrder.indexOf(a).compareTo(daysOrder.indexOf(b));
          });

        for (String day in sortedDays) {
          List<Map<String, String>> slots = workingHours[day] ?? [];
          if (slots.isNotEmpty) {
            workingHoursList.add({
              "day": day,
              "open": slots.first['open'] ?? "09:00 AM",
              "close": slots.first['close'] ?? "06:00 PM",
            });
          }
        }

        fields["working_hours"] = jsonEncode(workingHoursList);

        log("Working hours being sent to backend (Granular Format):");
        log("  Data: ${jsonEncode(workingHoursList)}");
      } else {
        // Add default working hours if none provided
        List<Map<String, dynamic>> defaultWorkingHours = [
          {"day": "Mon", "open": "09:00 AM", "close": "06:00 PM"},
        ];
        fields["working_hours"] = jsonEncode(defaultWorkingHours);
      }

      // Prepare files - only include image if provided
      Map<String, File>? files;
      if (imageFile != null) {
        files = {"photo": imageFile};
        log("Image File: ${imageFile.path}");
        log("Image File exists: ${await imageFile.exists()}");
        log("Image File size: ${await imageFile.length()} bytes");
      } else {
        log("No image file provided - shop will be created without image");
      }

      log("=== ADD SHOP API CALL ===");
      log("User ID: $userId (type: ${userId.runtimeType})");
      log("API URL: ${AppRoutes.domainName}/api/shop/add");
      log("Form Fields: $fields");

      final response = await ApiService.postMultipart(
        '/api/shop/add',
        fields: fields,
        files: files,
      );

      log("=== ADD SHOP RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          log("✅ Shop added successfully!");
          log("Shop ID: ${data['shopId']}");
          log("Photo URL: ${data['photo_url']}");

          // AppSnackBar.show(
          //   message: data['message'] ?? "Shop added successfully!",
          //   type: SnackType.success,
          // );
        } catch (_) {
          data = {"message": response.body};
          // AppSnackBar.show(
          //   message: "Shop added successfully!",
          //   type: SnackType.success,
          // );
        }

        return true;
      } else if (response.statusCode == 401) {
        // Handle 401 Unauthorized error
        log("❌ Authentication error - token expired or invalid");
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {"message": "Your session has expired. Please login again."};
        }

        // Clear auth status so UI knows to show session expired dialog
        await SharedPrefUtils.init();
        await SharedPrefUtils.setBool('is_logged_in', false);
        log("🧹 Cleared is_logged_in flag for UI to detect auth error");

        // Don't auto-redirect here. Let the UI handle it with a proper error dialog
        log("📌 Returning false for 401 error - UI will handle redirect");

        // AppSnackBar.show(
        //   message: data['message'] ?? "Session expired. Please login again.",
        //   type: SnackType.error,
        // );
        return false;
      } else {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {"message": response.body};
        }

        log("❌ Error adding shop - Status code: ${response.statusCode}");
        log("Response: ${data['message']}");

        // AppSnackBar.show(
        //   message: data['message'] ?? "Error while adding shop.",
        //   type: SnackType.error,
        // );
        return false;
      }
    } catch (e) {
      log("Exception: $e");
      // AppSnackBar.show(
      //   message: "Error: $e",
      //   type: SnackType.error,
      // );
      return false;
    }
  }

  // Clear form
  void clearForm() {
    shopNameController.clear();
    ownerNameController.clear();
    shopTypeController.clear();
    pinCodeController.clear();
    shopAddressController.clear();
    locationController.clear();
    photoUrlController.clear();
    contactNumberController.clear();
  }

  // Populate form for editing
  void populateFormForEdit(ShopModel shop) {
    shopNameController.text = shop.shopName;
    ownerNameController.text = shop.ownerName;
    shopTypeController.text = shop.shopType;
    pinCodeController.text = shop.pinCode;
    shopAddressController.text = shop.shopAddress;
    locationController.text = shop.location;
    contactNumberController.text = shop.contactNumber;
    photoUrlController.text = shop.photoUrl;
  }
}

class ShopListController extends GetxController {
  // Observable variables for shop list
  RxList<ShopModel> shops = <ShopModel>[].obs;
  RxBool isLoadingShops = false.obs;
  RxString errorMessage = ''.obs;

  // Helper method to convert 12-hour format to 24-hour format
  String _convertTo24HourFormat(String time12Hour) {
    try {
      log("🕐 Converting time: '$time12Hour'");

      // Handle formats like "9:00 AM", "09:00 AM", "8:00 PM", "08:00 PM"
      String cleanTime = time12Hour.trim().toUpperCase();
      log("🕐 Cleaned time: '$cleanTime'");

      // Extract time and period
      List<String> parts = cleanTime.split(' ');
      if (parts.length != 2) {
        log("❌ Invalid time format: $time12Hour (parts: $parts)");
        return "09:00:00"; // Default fallback
      }

      String timePart = parts[0];
      String period = parts[1];
      log("🕐 Time part: '$timePart', Period: '$period'");

      // Parse hour and minute
      List<String> timeComponents = timePart.split(':');
      if (timeComponents.length < 2) {
        log("❌ Invalid time components: $timePart");
        return "09:00:00"; // Default fallback
      }

      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);
      log("🕐 Parsed hour: $hour, minute: $minute");

      // Convert to 24-hour format
      if (period == "AM") {
        if (hour == 12) hour = 0; // 12:00 AM = 00:00
        log("🕐 AM conversion: hour = $hour");
      } else if (period == "PM") {
        if (hour != 12) hour += 12; // 1:00 PM = 13:00, but 12:00 PM = 12:00
        log("🕐 PM conversion: hour = $hour");
      }

      // Format as HH:mm:ss
      String hourStr = hour.toString().padLeft(2, '0');
      String minuteStr = minute.toString().padLeft(2, '0');
      String result = "$hourStr:$minuteStr:00";

      log("🕐 Final result: '$result'");
      return result;
    } catch (e) {
      log("❌ Error converting time to 24-hour format: $time12Hour - $e");
      return "09:00:00"; // Default fallback
    }
  }

  // Helper method to format time range from 24-hour to 12-hour format
  String _formatTimeRange(String openTime, String closeTime) {
    try {
      // Parse open time (format: "09:00:00")
      List<String> openParts = openTime.split(':');
      int openHour = int.parse(openParts[0]);
      int openMinute = int.parse(openParts[1]);

      // Parse close time (format: "18:00:00")
      List<String> closeParts = closeTime.split(':');
      int closeHour = int.parse(closeParts[0]);
      int closeMinute = int.parse(closeParts[1]);

      // Format open time
      String openFormatted = _formatTime(openHour, openMinute);

      // Format close time
      String closeFormatted = _formatTime(closeHour, closeMinute);

      return "$openFormatted - $closeFormatted";
    } catch (e) {
      log("Error formatting time range: $e");
      return "09:00 AM - 06:00 PM"; // Default fallback
    }
  }

  // Helper method to format individual time
  String _formatTime(int hour, int minute) {
    String period = hour >= 12 ? "PM" : "AM";
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$displayHour:$minuteStr $period";
  }

  // Fetch shops for the logged-in user
  Future<void> fetchShops() async {
    try {
      isLoadingShops.value = true;
      errorMessage.value = '';

      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        // AppSnackBar.show(
        //   message: "User not authenticated. Please login again.",
        //   type: SnackType.error,
        // );
        return;
      }

      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        // AppSnackBar.show(
        //   message: "Invalid user ID. Please login again.",
        //   type: SnackType.error,
        // );
        return;
      }

      log("=== FETCH SHOPS API CALL ===");
      log("User ID: $userId");
      log("API URL: ${AppRoutes.domainName}/api/shop/user/$userId");

      final response = await ApiService.get('/api/shop/user/$userId');

      log("=== FETCH SHOPS RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<ShopModel> shopList = [];

          // Handle different response formats
          if (data is List) {
            // Direct array of shops
            shopList = data.map((shop) => ShopModel.fromJson(shop)).toList();
          } else if (data is Map && data['data'] != null) {
            // Response with data wrapper
            List<dynamic> shopsData = data['data'];
            shopList = shopsData
                .map((shop) => ShopModel.fromJson(shop))
                .toList();
          } else if (data is Map && data['shops'] != null) {
            // Response with shops wrapper
            List<dynamic> shopsData = data['shops'];
            shopList = shopsData
                .map((shop) => ShopModel.fromJson(shop))
                .toList();
          }

          shops.value = shopList;
          log("✅ Successfully fetched ${shopList.length} shops");
        } catch (e) {
          log("❌ Error parsing shops response: $e");
          errorMessage.value = "Error parsing shops data";
          // AppSnackBar.show(
          //   message: "Error loading shops. Please try again.",
          //   type: SnackType.error,
          // );
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to fetch shops";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
          // AppSnackBar.show(
          //   message: errorMsg,
          //   type: SnackType.error,
          // );
        } catch (e) {
          errorMessage.value = "Failed to fetch shops";
          log("❌ Error parsing error response: $e");
          // AppSnackBar.show(
          //   message: "Failed to fetch shops. Please try again.",
          //   type: SnackType.error,
          // );
        }
      }
    } catch (e) {
      log("Error fetching shops: $e");
      errorMessage.value = "Network error occurred";
      // AppSnackBar.show(
      //   message: "Network error. Please check your connection.",
      //   type: SnackType.error,
      // );
    } finally {
      isLoadingShops.value = false;
    }
  }

  // Edit shop
  Future<bool> editShop({
    required int shopId,
    required String shopName,
    required String ownerName,
    required String shopType,
    required String pinCode,
    required String shopAddress,
    required String location,
    required String contactNumber,
    File? imageFile, // Changed from required String photoUrl
    Map<String, List<Map<String, String>>>? workingHours,
  }) async {
    // ✅ Basic validation
    if (shopName.isEmpty ||
        ownerName.isEmpty ||
        shopType.isEmpty ||
        pinCode.isEmpty ||
        shopAddress.isEmpty ||
        location.isEmpty ||
        contactNumber.isEmpty) {
      return false;
    }

    try {
      log("=== EDIT SHOP API CALL ===");
      log("Shop ID: $shopId");
      log("API URL: ${AppRoutes.domainName}/api/shop/edit/$shopId");

      Map<String, String> fields = {
        "shop_name": (shopName ?? '').trim(),
        "owner_name": (ownerName ?? '').trim(),
        "shop_type": (shopType ?? '').trim(),
        "pin_code": (pinCode ?? '').trim(),
        "shop_address": (shopAddress ?? '').trim(),
        "location": (location ?? '').trim(),
        "number": (contactNumber ?? '').trim(),
      };

      // Add working hours if provided - matching new API spec
      if (workingHours != null && workingHours.isNotEmpty) {
        // Create a granular list of working hours (one object per day)
        List<Map<String, dynamic>> workingHoursList = [];

        // Sort days for consistency
        List<String> sortedDays = workingHours.keys.toList()
          ..sort((a, b) {
            const daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return daysOrder.indexOf(a).compareTo(daysOrder.indexOf(b));
          });

        for (String day in sortedDays) {
          List<Map<String, String>> slots = workingHours[day] ?? [];
          if (slots.isNotEmpty) {
            workingHoursList.add({
              "day": day,
              "open": slots.first['open'] ?? "09:00 AM",
              "close": slots.first['close'] ?? "06:00 PM",
            });
          }
        }

        fields["working_hours"] = jsonEncode(workingHoursList);

        log(
          "Edit shop - Working hours being sent to backend (Granular Format):",
        );
        log("  Data: ${jsonEncode(workingHoursList)}");
      }

      Map<String, File>? files;
      if (imageFile != null) {
        files = {"photo": imageFile};
        log("Image File: ${imageFile.path}");
        log("Image File exists: ${await imageFile.exists()}");
        log("Image File size: ${await imageFile.length()} bytes");
      }

      final response = await ApiService.putMultipart(
        '/api/shop/edit/$shopId',
        fields: fields,
        files: files,
      );

      log("=== EDIT SHOP RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {"message": response.body};
        }

        // Refresh the shops list
        await fetchShops();
        return true;
      } else {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {"message": response.body};
        }

        // AppSnackBar.show(
        //   message: data['message'] ?? "Error while updating shop.",
        //   type: SnackType.error,
        // );
        return false;
      }
    } catch (e) {
      log("Exception: $e");
      // AppSnackBar.show(
      //   message: "Error: $e",
      //   type: SnackType.error,
      // );
      return false;
    }
  }

  // Refresh shops
  Future<void> refreshShops() async {
    await fetchShops();
  }

  // Delete shop
  Future<bool> deleteShop(int shopId) async {
    try {
      log("=== DELETE SHOP API CALL ===");
      log("Shop ID: $shopId");
      log("API URL: ${AppRoutes.domainName}/api/shop/delete/$shopId");

      final response = await ApiService.delete('/api/shop/delete/$shopId');

      log("=== DELETE SHOP RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Optimistically remove from list
        shops.removeWhere((s) => s.id == shopId);
        // Ensure list is up to date from server
        await fetchShops();
        // AppSnackBar.show(
        //   message: "Shop deleted successfully",
        //   type: SnackType.success,
        // );
        return true;
      } else {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {"message": response.body};
        }
        // AppSnackBar.show(
        //   message: data['message'] ?? "Failed to delete shop",
        //   type: SnackType.error,
        // );
        return false;
      }
    } catch (e) {
      log("Exception: $e");
      // AppSnackBar.show(
      //   message: "Error: $e",
      //   type: SnackType.error,
      // );
      return false;
    }
  }
}
