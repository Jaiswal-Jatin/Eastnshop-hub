import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';

import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';
import '../Utils/RefreshService.dart';
import '../Utils/SharedPrefUtils.dart';

class InactiveOffersController extends GetxController {
  // Observable variables
  RxList<Map<String, dynamic>> offers = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> shops = <Map<String, dynamic>>[].obs;
  RxBool isLoadingOffers = false.obs;
  RxBool isLoadingShops = false.obs;
  RxString errorMessage = ''.obs;
  RxString selectedShopId = ''.obs;
  RxString selectedShopName = ''.obs;

  // Filtered offers by category
  RxMap<String, List<Map<String, dynamic>>> filteredOffers = <String, List<Map<String, dynamic>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch shops for dropdown selection
    fetchShops();
    
    // Listen to global refresh events
    ever(RefreshService.to.refreshTrigger, (int trigger) {
      log("🔄 InactiveOffersController: Received refresh trigger $trigger");
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
        return;
      }
      
      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
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
            log("Shop $i: ID=${shopList[i]['id']}, Name=${shopList[i]['shop_name']}");
          }
          
        } catch (e) {
          log("❌ Error parsing shops response: $e");
          errorMessage.value = "Error parsing shops data";
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to fetch shops";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Failed to fetch shops";
          log("❌ Error parsing error response: $e");
        }
      }
    } catch (e) {
      log("Error fetching shops: $e");
      errorMessage.value = "Network error: ${e.toString()}";
    } finally {
      isLoadingShops.value = false;
    }
  }

  // Fetch inactive offers for selected shop
  Future<void> fetchOffersByShopId(String shopId) async {
    try {
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

      log("=== FETCH INACTIVE OFFERS API CALL ===");
      log("Shop ID: $shopId");
      log("User ID: $userIdStr");
      log("API URL: ${AppRoutes.domainName}/api/offer/user/$userIdStr/inactive");

      final response = await ApiService.get('/api/offer/user/$userIdStr/inactive');

      log("=== FETCH INACTIVE OFFERS RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> rawOfferList = [];
          
          // Handle different response formats
          if (data is List) {
            rawOfferList = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            rawOfferList = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is Map && data['offers'] != null) {
            rawOfferList = List<Map<String, dynamic>>.from(data['offers']);
          }
          
          // Filter by shop ID
          List<Map<String, dynamic>> filteredList = [];
          if (shopId.isNotEmpty) {
            filteredList = rawOfferList.where((offer) {
              return offer['shop_id']?.toString() == shopId;
            }).toList();
            log("🔍 Filtering by Shop ID: $shopId. Found ${filteredList.length} matches out of ${rawOfferList.length} total.");
          } else {
            filteredList = rawOfferList;
            log("ℹ️ No Shop ID provided for further filtering, showing all ${filteredList.length} items from endpoint.");
          }
          
          offers.value = filteredList;
          filterOffersByCategory();
          log("✅ Successfully loaded ${filteredList.length} inactive offers for categorization");
          
        } catch (e) {
          log("❌ Error parsing inactive offers response: $e");
          errorMessage.value = "Error parsing inactive offers data";
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to fetch inactive offers";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Failed to fetch inactive offers";
          log("❌ Error parsing error response: $e");
        }
      }
    } catch (e) {
      log("Error fetching inactive offers: $e");
      errorMessage.value = "Network error: ${e.toString()}";
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
    var otherCategories = categorizedOffers.keys.where((key) => key != 'General').toList()..sort();
    for (var category in otherCategories) {
      sortedOffers[category] = categorizedOffers[category]!;
    }
    
    filteredOffers.value = sortedOffers;
    log("✅ Categorized inactive offers into ${sortedOffers.length} categories: ${sortedOffers.keys.toList()}");
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
    log("✅ Cleared inactive offers data");
  }

  // Submit selected shop and fetch offers
  Future<void> submitAndFetchOffers() async {
    if (selectedShopId.value.isEmpty) {
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
    log("🔄 Refreshing all inactive offers data...");
    await fetchShops();
    
    // Maintain the currently selected shop if any, otherwise don't fetch offers yet
    if (selectedShopId.value.isNotEmpty) {
      log("🔄 Shop selected, refreshing offers for shop: ${selectedShopId.value}");
      await fetchOffersByShopId(selectedShopId.value);
    } else {
      log("🔄 No shop selected, skipping inactive offers fetch during refresh");
    }
  }

  // Reactivate offer (make it active again)
  Future<bool> reactivateOffer(String offerId) async {
    try {
      isLoadingOffers.value = true;
      errorMessage.value = '';

      log("=== REACTIVATE OFFER API CALL ===");
      log("Offer ID: $offerId");
      log("API URL: ${AppRoutes.domainName}/api/offer/active/$offerId");

      final response = await ApiService.patch('/api/offer/active/$offerId', body: {});

      log("=== REACTIVATE OFFER RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          log("✅ Offer reactivated successfully!");
          log("Response Data: $data");

          // Refresh offers after successful reactivation
          await fetchOffersByShopId(selectedShopId.value.isNotEmpty ? selectedShopId.value : '');
          
          // Trigger global refresh to update Active offers page
          log("🔄 Triggering global refresh after offer reactivation");
          RefreshService.to.triggerOfferRefresh();
          
          return true;
        } catch (e) {
          log("⚠️ Could not parse response JSON: $e");
          await fetchOffersByShopId(selectedShopId.value.isNotEmpty ? selectedShopId.value : '');
          return true;
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to reactivate offer";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Failed to reactivate offer";
          log("❌ Error parsing error response: $e");
        }
        return false;
      }
    } catch (e) {
      log("Error reactivating offer: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      return false;
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Delete offer permanently
  Future<bool> deleteOffer(String offerId) async {
    try {
      isLoadingOffers.value = true;
      errorMessage.value = '';

      log("=== DELETE OFFER API CALL ===");
      log("Offer ID: $offerId");
      log("API URL: ${AppRoutes.domainName}/api/offer/delete/$offerId");

      var response = await ApiService.delete('/api/offer/delete/$offerId');

      log("=== DELETE OFFER RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          dynamic data = jsonDecode(response.body);
          log("✅ Offer deleted successfully!");
          log("Response Data: $data");

          // Refresh offers after successful deletion
          await fetchOffersByShopId(selectedShopId.value.isNotEmpty ? selectedShopId.value : '');
          
          // Trigger global refresh to update Active offers page
          log("🔄 Triggering global refresh after offer deletion");
          RefreshService.to.triggerOfferRefresh();
          
          return true;
        } catch (e) {
          log("⚠️ Could not parse response JSON: $e");
          await fetchOffersByShopId(selectedShopId.value.isNotEmpty ? selectedShopId.value : '');
          
          // Trigger global refresh to update Active offers page
          log("🔄 Triggering global refresh after offer deletion");
          RefreshService.to.triggerOfferRefresh();
          
          return true;
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to delete offer";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Failed to delete offer";
          log("❌ Error parsing error response: $e");
        }
        return false;
      }
    } catch (e) {
      log("Error deleting offer: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      return false;
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Static method to create controller with shop ID
  static InactiveOffersController createWithShopId(String shopId) {
    final controller = InactiveOffersController();
    controller.fetchOffersDirectly(shopId);
    return controller;
  }
}
