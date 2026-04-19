import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';
import '../Utils/RefreshService.dart';
import '../Utils/SharedPrefUtils.dart';

class OfferController extends GetxController {
  // Shop data
  RxList<Map<String, dynamic>> shops = <Map<String, dynamic>>[].obs;
  RxBool isLoadingShops = false.obs;
  RxBool isCreatingOffer = false.obs;
  RxBool isAdLimitReached = false.obs;
  RxBool isSubscriptionExpired = false.obs;

  // Offer types data
  RxList<Map<String, dynamic>> offerTypes = <Map<String, dynamic>>[].obs;
  RxBool isLoadingOfferTypes = false.obs;

  // Offer form controllers
  TextEditingController productNameController = TextEditingController();
  TextEditingController productBrandController = TextEditingController();
  TextEditingController productPriceController = TextEditingController();
  TextEditingController offerPriceController = TextEditingController();
  TextEditingController offerDescriptionController = TextEditingController();

  // Selected values
  RxString selectedShopId = ''.obs;
  RxString selectedShopName = ''.obs;
  RxString selectedOfferType = ''.obs;
  RxString selectedDesign = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchShops();
    fetchOfferTypes();
    log("=== OFFER CONTROLLER INITIALIZED ===");
    log("Offer types count: ${offerTypes.length}");
  }

  // Fetch shops for the logged-in user
  Future<void> fetchShops() async {
    try {
      isLoadingShops.value = true;

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

      log("=== SHOP FETCH API CALL ===");
      log("User ID: $userId");
      log("API URL: ${AppRoutes.domainName}/api/shop/user/$userId");

      final response = await ApiService.get('/api/shop/user/$userId');

      log("=== SHOP FETCH RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        dynamic data = jsonDecode(response.body);
        log("=== PARSED SHOP DATA ===");
        log("Data Type: ${data.runtimeType}");
        log("Raw Data: $data");

        if (data is List) {
          shops.value = List<Map<String, dynamic>>.from(data);
          log("✅ Fetched ${shops.length} shops from List format");
          for (int i = 0; i < shops.length; i++) {
            log("Shop $i: ID=${shops[i]['id']}, Name=${shops[i]['shop_name']}");
          }
        } else if (data is Map && data['shops'] != null) {
          shops.value = List<Map<String, dynamic>>.from(data['shops']);
          log("✅ Fetched ${shops.length} shops from nested format");
          for (int i = 0; i < shops.length; i++) {
            log("Shop $i: ID=${shops[i]['id']}, Name=${shops[i]['shop_name']}");
          }
        } else {
          log("❌ Unexpected response format: $data");
          shops.value = [];
        }
      } else {
        log(
          "❌ Failed to fetch shops: ${response.statusCode} - ${response.body}",
        );
        // AppSnackBar.show(
        //   message: "Failed to fetch shops. Please try again.",
        //   type: SnackType.error,
        // );
      }
    } catch (e) {
      log("Error fetching shops: $e");
      // AppSnackBar.show(
      //   message: "Error fetching shops: $e",
      //   type: SnackType.error,
      // );
    } finally {
      isLoadingShops.value = false;
    }
  }

  // Fetch offer types from API
  Future<void> fetchOfferTypes() async {
    try {
      isLoadingOfferTypes.value = true;

      log("=== OFFER TYPES FETCH API CALL ===");
      log("API URL: ${AppRoutes.domainName}/api/offer-types");

      final response = await ApiService.get(
        '/api/offer-types',
        includeAuth: false,
      );

      log("=== OFFER TYPES FETCH RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        dynamic data = jsonDecode(response.body);
        log("=== PARSED OFFER TYPES DATA ===");
        log("Data Type: ${data.runtimeType}");
        log("Raw Data: $data");

        if (data is List) {
          offerTypes.value = List<Map<String, dynamic>>.from(data);
          log("✅ Fetched ${offerTypes.length} offer types from List format");
          for (int i = 0; i < offerTypes.length; i++) {
            log("Offer Type $i: ${offerTypes[i]['type_name']}");
          }
        } else if (data is Map && data['data'] != null) {
          // Handle the actual API response format: {"total":4,"limit":50,"offset":0,"data":[...]}
          offerTypes.value = List<Map<String, dynamic>>.from(data['data']);
          log("✅ Fetched ${offerTypes.length} offer types from 'data' field");
          for (int i = 0; i < offerTypes.length; i++) {
            log("Offer Type $i: ${offerTypes[i]['type_name']}");
          }
        } else if (data is Map && data['offer_types'] != null) {
          offerTypes.value = List<Map<String, dynamic>>.from(
            data['offer_types'],
          );
          log(
            "✅ Fetched ${offerTypes.length} offer types from 'offer_types' field",
          );
          for (int i = 0; i < offerTypes.length; i++) {
            log("Offer Type $i: ${offerTypes[i]['type_name']}");
          }
        } else {
          log("❌ Unexpected response format: $data");
          offerTypes.value = [];
        }
      } else {
        log(
          "❌ Failed to fetch offer types: ${response.statusCode} - ${response.body}",
        );
        // Fallback to hardcoded types if API fails
        offerTypes.value = [
          {'type_name': 'General'},
          {'type_name': 'Festival'},
          {'type_name': 'New year'},
          {'type_name': 'Bumper'},
          {'type_name': 'Big Dhamaka'},
        ];
        log("⚠️ Using fallback offer types");
      }
    } catch (e) {
      log("Error fetching offer types: $e");
      // Fallback to hardcoded types if API fails
      offerTypes.value = [
        {'type_name': 'General'},
        {'type_name': 'Festival'},
        {'type_name': 'New year'},
        {'type_name': 'Bumper'},
        {'type_name': 'Big Dhamaka'},
      ];
      log("⚠️ Using fallback offer types due to error");
    } finally {
      isLoadingOfferTypes.value = false;
      log("=== OFFER TYPES FETCH COMPLETED ===");
      log("Final offer types count: ${offerTypes.length}");
      for (int i = 0; i < offerTypes.length; i++) {
        log("Offer Type $i: ${offerTypes[i]['type_name']}");
      }
    }
  }

  // Manual refresh method for debugging
  Future<void> refreshOfferTypes() async {
    log("=== MANUAL REFRESH OFFER TYPES ===");
    await fetchOfferTypes();
  }

  // Create offer
  Future<bool> createOffer({List<File>? imageFiles}) async {
    try {
      isCreatingOffer.value = true;

      // Validate required fields
      log("=== FORM VALIDATION ===");
      log("Selected Shop ID: '${selectedShopId.value}'");
      log("Selected Offer Type: '${selectedOfferType.value}'");
      log("Product Name: '${productNameController.text}'");
      log("Product Brand: '${productBrandController.text}'");
      log("Product Price: '${productPriceController.text}'");
      log("Offer Price: '${offerPriceController.text}'");
      log("Offer Description: '${offerDescriptionController.text}'");
      log("Selected Design: '${selectedDesign.value}'");

      if (selectedShopId.value.isEmpty) {
        log("❌ Validation failed: No shop selected");
        return false;
      }

      if (selectedOfferType.value.isEmpty) {
        log("❌ Validation failed: No offer type selected");
        return false;
      }

      if (productNameController.text.isEmpty) {
        log("❌ Validation failed: Product name is empty");
        return false;
      }

      if (productBrandController.text.isEmpty) {
        log("❌ Validation failed: Product brand is empty");
        return false;
      }

      if (productPriceController.text.isEmpty) {
        log("❌ Validation failed: Product price is empty");
        return false;
      }

      if (offerPriceController.text.isEmpty) {
        log("❌ Validation failed: Offer price is empty");
        return false;
      }

      log("✅ All form validations passed");

      // Extract design number from selected design path
      String designNumber = getDesignNumber();
      log("=== DESIGN NUMBER EXTRACTION ===");
      log("Selected Design Path: ${selectedDesign.value}");
      log("Extracted Design Number: $designNumber");

      log("=== OFFER CREATION API CALL ===");
      log("Selected Shop ID: ${selectedShopId.value}");
      log("Selected Shop Name: ${selectedShopName.value}");
      log("Design Number: $designNumber");

      // Call the new API method
      Map<String, dynamic> result = await ApiService.createOffer(
        shopId: int.parse(selectedShopId.value),
        offerType: selectedOfferType.value,
        productPrice: double.parse(productPriceController.text),
        offerPrice: double.parse(offerPriceController.text),
        productName: productNameController.text.trim(),
        productBrand: productBrandController.text.trim(),
        offerDesign: designNumber,
        offerDescription: offerDescriptionController.text.trim(),
        imageFiles: imageFiles,
      );

      log("=== OFFER CREATION RESPONSE ===");
      log("Result: $result");

      if (result['success'] == true) {
        log("✅ Offer created successfully!");
        log("Response Data: ${result['data']}");

        // Clear form after successful creation
        log("Clearing form after successful offer creation");
        clearForm();

        // Trigger global refresh to update ActiveOffer and UserHome pages
        log("🔄 Triggering global refresh after offer creation");
        RefreshService.to.triggerOfferRefresh();

        return true;
      } else if (result['isSubscriptionExpired'] == true) {
        // Handle 402 - Subscription expired
        log("❌ Subscription expired - no active plan");
        isSubscriptionExpired.value = true;
        return false; // Will be handled by the UI to show custom dialog
      } else if (result['isAdLimitReached'] == true) {
        // Handle 403 - Ad limit reached
        log("❌ Ad limit reached for current plan");
        isAdLimitReached.value = true;
        return false; // Will be handled by the UI to show custom dialog
      } else {
        // Handle other errors
        log("❌ Offer creation failed: ${result['error']}");
        // AppSnackBar.show(
        //   message: result['error'] ?? "Failed to create offer. Please try again.",
        //   type: SnackType.error,
        // );
        return false;
      }
    } catch (e) {
      log("Error creating offer: $e");
      // AppSnackBar.show(
      //   message: "Error creating offer: $e",
      //   type: SnackType.error,
      // );
      return false;
    } finally {
      isCreatingOffer.value = false;
    }
  }

  // Clear form
  void clearForm() {
    productNameController.clear();
    productBrandController.clear();
    productPriceController.clear();
    offerPriceController.clear();
    offerDescriptionController.clear();
    selectedShopId.value = '';
    selectedShopName.value = '';
    selectedOfferType.value = '';
    selectedDesign.value = '';
    isAdLimitReached.value = false;
    isSubscriptionExpired.value = false;
  }

  // Reset ad limit flag
  void resetAdLimitFlag() {
    isAdLimitReached.value = false;
  }

  // Reset subscription expired flag
  void resetSubscriptionExpiredFlag() {
    isSubscriptionExpired.value = false;
  }

  // Calculate discount percentage
  double calculateDiscount() {
    final productPrice = double.tryParse(productPriceController.text);
    final offerPrice = double.tryParse(offerPriceController.text);

    if (productPrice != null && offerPrice != null && productPrice > 0) {
      return ((productPrice - offerPrice) / productPrice) * 100;
    }
    return 0.0;
  }

  // Extract design number from asset path
  String getDesignNumber() {
    if (selectedDesign.value.isEmpty) {
      return "1"; // Default to design 1
    }

    // Extract number from path like "assets/offerdesign2.png" -> "2"
    RegExp regex = RegExp(r'offerdesign(\d+)\.png');
    Match? match = regex.firstMatch(selectedDesign.value);
    if (match != null) {
      return match.group(1) ?? "1";
    }

    return "1"; // Default fallback
  }
}
