import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';

import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';
import '../Utils/RefreshService.dart';
import '../Utils/SharedPrefUtils.dart';

class ActiveOffersController extends GetxController {
  // Observable variables
  RxList<Map<String, dynamic>> offers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> shops = <Map<String, dynamic>>[].obs;
  RxBool isLoadingOffers = false.obs;
  RxBool isLoadingShops = false.obs;
  RxString errorMessage = ''.obs;
  RxString selectedShopId = ''.obs;
  RxString selectedShopName = ''.obs;

  // Filtered offers by category
  RxMap<String, List<Map<String, dynamic>>> filteredOffers =
      <String, List<Map<String, dynamic>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch shops for dropdown selection
    fetchShops();

    // Listen to global refresh events
    ever(RefreshService.to.refreshTrigger, (int trigger) {
      log("🔄 ActiveOffersController: Received refresh trigger $trigger");
      refreshAllData();
    });
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
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> shopList = [];

          // Handle different response formats
          if (data is List) {
            shopList = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            shopList = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is Map && data['shops'] != null) {
            shopList = List<Map<String, dynamic>>.from(data['shops']);
          }

          shops.value = shopList;
          log("✅ Successfully fetched ${shopList.length} shops");
          for (int i = 0; i < shopList.length; i++) {
            log(
              "Shop $i: ID=${shopList[i]['id']}, Name=${shopList[i]['shop_name']}",
            );
          }
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
      errorMessage.value = "Network error: ${e.toString()}";
      // AppSnackBar.show(
      //   message: "Error fetching shops: $e",
      //   type: SnackType.error,
      // );
    } finally {
      isLoadingShops.value = false;
    }
  }

  // Fetch offers for selected shop
  Future<void> fetchOffersByShopId(String shopId) async {
    try {
      // Validate shop ID before making API call
      if (shopId.isEmpty) {
        log("❌ Shop ID is empty, skipping offers fetch");
        errorMessage.value = "Please select a shop first";
        return;
      }

      isLoadingOffers.value = true;
      errorMessage.value = '';
      offers.clear();
      filteredOffers.clear();

      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        errorMessage.value = "User not authenticated. Please login again.";
        log("❌ User ID not found in SharedPreferences");
        return;
      }

      log("=== FETCH OFFERS API CALL ===");
      log("Shop ID: $shopId");
      log("User ID: $userIdStr");
      log("API URL: ${AppRoutes.domainName}/api/offer/shop/$shopId/active");

      final response = await ApiService.get('/api/offer/shop/$shopId/active');

      log("=== FETCH OFFERS RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> offerList = [];

          // Handle different response formats
          if (data is List) {
            offerList = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            offerList = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is Map && data['offers'] != null) {
            offerList = List<Map<String, dynamic>>.from(data['offers']);
          }

          offers.value = offerList;
          filterOffersByCategory();
          log("✅ Successfully fetched ${offerList.length} offers");
        } catch (e) {
          log("❌ Error parsing offers response: $e");
          errorMessage.value = "Error parsing offers data";
          // AppSnackBar.show(
          //   message: "Error loading offers. Please try again.",
          //   type: SnackType.error,
          // );
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to fetch offers";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
          // AppSnackBar.show(
          //   message: errorMsg,
          //   type: SnackType.error,
          // );
        } catch (e) {
          errorMessage.value = "Failed to fetch offers";
          log("❌ Error parsing error response: $e");
          // AppSnackBar.show(
          //   message: "Failed to fetch offers. Please try again.",
          //   type: SnackType.error,
          // );
        }
      }
    } catch (e) {
      log("Error fetching offers: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      // AppSnackBar.show(
      //   message: "Error fetching offers: $e",
      //   type: SnackType.error,
      // );
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Filter offers by category (offer_type)
  void filterOffersByCategory() {
    Map<String, List<Map<String, dynamic>>> categorizedOffers = {};

    for (var offer in offers) {
      String category = offer['offer_type']?.toString() ?? 'General';

      // Normalize category for consistent display
      String normalizedCategory = _normalizeCategoryForDisplay(category);

      // Debug logging for category normalization
      if (category != normalizedCategory) {
        log("🔄 Normalized category: '$category' -> '$normalizedCategory'");
      }

      if (!categorizedOffers.containsKey(normalizedCategory)) {
        categorizedOffers[normalizedCategory] = [];
      }
      categorizedOffers[normalizedCategory]!.add(offer);
    }

    // Sort categories to show General first, then others alphabetically
    Map<String, List<Map<String, dynamic>>> sortedOffers = {};

    // Add General first if it exists
    if (categorizedOffers.containsKey('General')) {
      sortedOffers['General'] = categorizedOffers['General']!;
    }

    // Add other categories alphabetically
    var otherCategories =
        categorizedOffers.keys.where((key) => key != 'General').toList()
          ..sort();
    for (var category in otherCategories) {
      sortedOffers[category] = categorizedOffers[category]!;
    }

    filteredOffers.value = sortedOffers;
    log(
      "✅ Categorized offers into ${sortedOffers.length} categories: ${sortedOffers.keys.toList()}",
    );
  }

  // Normalize category for consistent display
  String _normalizeCategoryForDisplay(String category) {
    // Normalize different variations to consistent display format
    switch (category.toLowerCase()) {
      case 'new year':
        return 'New year'; // Display format
      case 'big dhamaka':
        return 'Big Dhamaka'; // Display format
      case 'general':
        return 'General';
      case 'festival':
        return 'Festival';
      case 'bumper':
        return 'Bumper';
      default:
        return 'General'; // Default fallback
    }
  }

  // Set selected shop
  void setSelectedShop(String shopId, String shopName) {
    selectedShopId.value = shopId;
    selectedShopName.value = shopName;
    log("Selected shop: $shopName (ID: $shopId)");
  }

  // Clear offers data
  void clearOffers() {
    offers.clear();
    filteredOffers.clear();
    errorMessage.value = '';
    log("✅ Cleared offers data");
  }

  // Submit selected shop and fetch offers
  Future<void> submitAndFetchOffers() async {
    if (selectedShopId.value.isEmpty) {
      // AppSnackBar.show(
      //   message: "Please select a shop first",
      //   type: SnackType.error,
      // );
      return;
    }

    await fetchOffersByShopId(selectedShopId.value);
  }

  // Direct method to fetch offers by shop ID (without shop selection)
  Future<void> fetchOffersDirectly(String shopId) async {
    selectedShopId.value = shopId;
    await fetchOffersByShopId(shopId);
  }

  // Get shop name by ID
  String getShopNameById(String shopId) {
    try {
      var shop = shops.firstWhere((shop) => shop['id'].toString() == shopId);
      return shop['shop_name'] ?? 'Unknown Shop';
    } catch (e) {
      return 'Unknown Shop';
    }
  }

  // Check if offers are available
  bool get hasOffers => offers.isNotEmpty;

  // Check if shops are available
  bool get hasShops => shops.isNotEmpty;

  // Refresh all data (shops and offers)
  Future<void> refreshAllData() async {
    log("🔄 Refreshing all data...");
    await fetchShops();

    // Only fetch offers if a shop is selected
    if (selectedShopId.value.isNotEmpty) {
      log(
        "🔄 Shop selected, fetching offers for shop: ${selectedShopId.value}",
      );
      await fetchOffersByShopId(selectedShopId.value);
    } else {
      log("🔄 No shop selected, skipping offers fetch");
    }
  }

  // Edit offer
  Future<bool> editOffer(
    Map<String, dynamic> offerData, {
    List<File>? imageFiles,
  }) async {
    try {
      isLoadingOffers.value = true;
      errorMessage.value = '';

      // Get offer ID from the offer data
      String offerId = offerData['id']?.toString() ?? '';
      log("=== EDIT OFFER DEBUG ===");
      log("Offer Data Keys: ${offerData.keys.toList()}");
      log("Offer ID from data: '$offerId'");
      log("Offer Data: $offerData");
      log("Image files count: ${imageFiles?.length ?? 0}");

      if (offerId.isEmpty) {
        log("❌ Offer ID is empty!");
        // AppSnackBar.show(
        //   message: "Offer ID not found. Cannot update offer.",
        //   type: SnackType.error,
        // );
        return false;
      }

      log("=== EDIT OFFER API CALL ===");
      log("Offer ID: $offerId");
      log("Shop ID: ${selectedShopId.value}");
      log("API URL: ${AppRoutes.domainName}/api/offer/edit/$offerId");
      log("Request Body: $offerData");

      // Use the ApiService.editOffer method which handles both JSON and multipart
      Map<String, dynamic> result = await ApiService.editOffer(
        offerId: int.parse(offerId),
        shopId: offerData['shop_id'] ?? 0,
        offerType: offerData['offer_type'] ?? '',
        productPrice: offerData['product_price'] ?? 0.0,
        offerPrice: offerData['offer_price'] ?? 0.0,
        productName: offerData['product_name'] ?? '',
        productBrand: offerData['product_brand'] ?? '',
        offerDesign: offerData['offer_design'] ?? 'simple',
        offerDescription: offerData['offer_description'] ?? '',
        imageFiles: imageFiles,
        photoUrl: offerData['photo_url'],
      );

      log("=== EDIT OFFER RESPONSE ===");
      log("Result: $result");

      if (result['success'] == true) {
        try {
          dynamic data = result['data'];
          log("✅ Offer updated successfully!");
          log("Response Data: $data");

          // Refresh offers after successful update
          await fetchOffersByShopId(
            selectedShopId.value.isNotEmpty ? selectedShopId.value : '',
          );

          // Trigger global refresh to update UserHome page
          log("🔄 Triggering global refresh after offer update");
          RefreshService.to.triggerOfferRefresh();

          return true;
        } catch (e) {
          log("⚠️ Could not parse response JSON: $e");
          await fetchOffersByShopId(
            selectedShopId.value.isNotEmpty ? selectedShopId.value : '',
          );
          return true;
        }
      } else if (result['isAdLimitReached'] == true) {
        // Handle 403 - Ad limit reached
        log("❌ Ad limit reached for current plan");
        // AppSnackBar.show(
        //   message: "Ad limit reached for current plan",
        //   type: SnackType.error,
        // );
        return false;
      } else {
        // Handle other errors
        String errorMsg = result['error'] ?? "Failed to update offer";
        errorMessage.value = errorMsg;
        log("❌ Offer update failed: $errorMsg");
        // AppSnackBar.show(
        //   message: errorMsg,
        //   type: SnackType.error,
        // );
        return false;
      }
    } catch (e) {
      log("Error updating offer: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      // AppSnackBar.show(
      //   message: "Error updating offer: $e",
      //   type: SnackType.error,
      // );
      return false;
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Delete offer (make inactive)
  Future<bool> deleteOffer(String offerId) async {
    try {
      isLoadingOffers.value = true;
      errorMessage.value = '';

      log("=== INACTIVATE OFFER API CALL ===");
      log("Offer ID: $offerId");
      log("Shop ID: ${selectedShopId.value}");
      log("API URL: ${AppRoutes.domainName}/api/offer/inactive/$offerId");

      // Use PATCH method to make offer inactive
      var response = await ApiService.patch(
        '/api/offer/inactive/$offerId',
        body: {},
      );

      log("=== INACTIVATE OFFER RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          dynamic data = jsonDecode(response.body);
          log("✅ Offer status updated to inactive successfully!");
          log("Response Data: $data");

          // Refresh offers after successful inactivation
          await fetchOffersByShopId(
            selectedShopId.value.isNotEmpty ? selectedShopId.value : '',
          );

          // Trigger global refresh to update UserHome page
          log("🔄 Triggering global refresh after offer inactivation");
          RefreshService.to.triggerOfferRefresh();

          return true;
        } catch (e) {
          log("⚠️ Could not parse response JSON: $e");
          await fetchOffersByShopId(
            selectedShopId.value.isNotEmpty ? selectedShopId.value : '',
          );

          // Trigger global refresh to update UserHome page
          log("🔄 Triggering global refresh after offer inactivation");
          RefreshService.to.triggerOfferRefresh();

          return true;
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg =
              errorData['message'] ?? "Failed to make offer inactive";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
          // AppSnackBar.show(
          //   message: errorMsg,
          //   type: SnackType.error,
          // );
        } catch (e) {
          errorMessage.value = "Failed to make offer inactive";
          log("❌ Error parsing error response: $e");
          // AppSnackBar.show(
          //   message: "Failed to make offer inactive. Please try again.",
          //   type: SnackType.error,
          // );
        }
        return false;
      }
    } catch (e) {
      log("Error making offer inactive: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      // AppSnackBar.show(
      //   message: "Error making offer inactive: $e",
      //   type: SnackType.error,
      // );
      return false;
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Test API endpoints to debug delete issue
  Future<void> testDeleteEndpoints(String offerId) async {
    log("=== TESTING DELETE ENDPOINTS ===");
    log("Testing offer ID: $offerId");

    final endpoints = [
      '/api/offer/delete/$offerId',
      '/api/offers/delete/$offerId',
      '/api/offer/$offerId',
      '/api/offers/$offerId',
    ];

    for (String endpoint in endpoints) {
      try {
        log("Testing endpoint: $endpoint");
        final response = await ApiService.delete(endpoint);
        log(
          "✅ $endpoint - Status: ${response.statusCode}, Body: ${response.body}",
        );
      } catch (e) {
        log("❌ $endpoint - Error: $e");
      }
    }

    log("=== ENDPOINT TESTING COMPLETE ===");
  }

  // Static method to create controller with shop ID
  static ActiveOffersController createWithShopId(String shopId) {
    final controller = ActiveOffersController();
    controller.fetchOffersDirectly(shopId);
    return controller;
  }
}
