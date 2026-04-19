import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../Utils/ApiService.dart';
import '../Utils/SharedPrefUtils.dart';

class OfferSearchController extends GetxController {
  // Observable variables
  RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString currentQuery = ''.obs;
  RxString currentBrand = ''.obs;
  RxString currentCategory = ''.obs;
  
  // Location variables
  RxDouble currentLatitude = 0.0.obs;
  RxDouble currentLongitude = 0.0.obs;
  RxBool hasLocation = false.obs;
  
  // Search history
  RxList<String> searchHistory = <String>[].obs;
  
  // Available brands and categories
  RxList<String> availableBrands = <String>[].obs;
  RxList<String> availableCategories = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    _loadSearchHistory();
    loadAvailableBrands();
  }
  
  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      log("📍 Getting current location...");
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log("❌ Location services are disabled");
        errorMessage.value = "Location services are disabled. Please enable location services.";
        return;
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log("❌ Location permissions are denied");
          errorMessage.value = "Location permissions are denied. Please grant location permissions.";
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        log("❌ Location permissions are permanently denied");
        errorMessage.value = "Location permissions are permanently denied. Please enable location permissions in settings.";
        return;
      }
      
      // Get current position with timeout handling
      Position position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log("⏰ Location request timed out after 5 seconds");
          throw TimeoutException('Location request timed out', const Duration(seconds: 5));
        },
      );
      
      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
      hasLocation.value = true;
      
      log("✅ Location obtained: ${position.latitude}, ${position.longitude}");
      
    } catch (e) {
      log("❌ Error getting location: $e");
      
      // Handle different types of location errors
      if (e is TimeoutException) {
        log("⏰ Location timeout - continuing without location");
        hasLocation.value = false;
        // Don't set error message for timeout, just continue without location
      } else {
        errorMessage.value = "Error getting location: $e";
        hasLocation.value = false;
      }
    }
  }
  
  // Filter offers by brand using the new filter API
  Future<void> filterOffersByBrand(String brand, {int limit = 20, int offset = 0}) async {
    if (brand.trim().isEmpty) {
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentBrand.value = brand.trim();
      
      log("🔍 Filtering offers by brand: '$brand'");
      log("📍 Location: ${currentLatitude.value}, ${currentLongitude.value}");
      
      // Build filter URL with parameters
      String filterUrl = '/api/filter/category?product_brand=${Uri.encodeComponent(brand.trim())}&limit=$limit&offset=$offset';
      
      log("🌐 Filter URL: $filterUrl");
      
      // Make API call
      final response = await ApiService.get(filterUrl, includeAuth: false);
      
      log("📥 Filter Response:");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> results = [];
          
          // Handle different response formats
          if (data is List) {
            results = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            results = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is Map && data['offers'] != null) {
            results = List<Map<String, dynamic>>.from(data['offers']);
          } else if (data is Map && data['results'] != null) {
            results = List<Map<String, dynamic>>.from(data['results']);
          }
          
          searchResults.value = results;
          log("✅ Filter completed: ${results.length} results found for brand '$brand'");
          
          // Extract unique brands and categories from results
          _extractBrandsAndCategories(results);
          
        } catch (e) {
          log("❌ Error parsing filter response: $e");
          errorMessage.value = "Error parsing filter results";
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Filter failed";
          errorMessage.value = errorMsg;
          log("❌ Filter API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Filter failed";
          log("❌ Error parsing error response: $e");
        }
      }
    } catch (e) {
      log("❌ Filter error: $e");
      errorMessage.value = "Network error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
  
  // Search offers with query, brand, category and location
  Future<void> searchOffers(String query, {String? brand, String? category}) async {
    if (query.trim().isEmpty) {
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentQuery.value = query.trim();
      currentBrand.value = brand ?? '';
      currentCategory.value = category ?? '';
      
      // Add to search history
      _addToSearchHistory(query.trim());
      
      log("🔍 Searching offers for: '$query'");
      if (brand != null && brand.isNotEmpty) {
        log("🏷️ Brand filter: '$brand'");
      }
      if (category != null && category.isNotEmpty) {
        log("📂 Category filter: '$category'");
      }
      log("📍 Location: ${currentLatitude.value}, ${currentLongitude.value}");
      
      // Build search URL with parameters
      String searchUrl = '/api/offer/search?q=${Uri.encodeComponent(query.trim())}';
      
      // Add brand parameter if provided
      if (brand != null && brand.trim().isNotEmpty) {
        searchUrl += '&brand=${Uri.encodeComponent(brand.trim())}';
      }
      
      // Add category parameter if provided
      if (category != null && category.trim().isNotEmpty) {
        searchUrl += '&category=${Uri.encodeComponent(category.trim())}';
      }
      
      // Add location parameters if available
      if (hasLocation.value) {
        searchUrl += '&lat=${currentLatitude.value}&lng=${currentLongitude.value}';
      }
      
      log("🌐 Search URL: $searchUrl");
      
      // Make API call
      final response = await ApiService.get(searchUrl, includeAuth: false);
      
      log("📥 Search Response:");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> results = [];
          
          // Handle different response formats
          if (data is List) {
            results = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            results = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is Map && data['offers'] != null) {
            results = List<Map<String, dynamic>>.from(data['offers']);
          } else if (data is Map && data['results'] != null) {
            results = List<Map<String, dynamic>>.from(data['results']);
          }
          
          searchResults.value = results;
          log("✅ Search completed: ${results.length} results found");
          
          // Extract unique brands and categories from results
          _extractBrandsAndCategories(results);
          
        } catch (e) {
          log("❌ Error parsing search response: $e");
          errorMessage.value = "Error parsing search results";
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Search failed";
          errorMessage.value = errorMsg;
          log("❌ Search API Error: $errorMsg");
        } catch (e) {
          errorMessage.value = "Search failed";
          log("❌ Error parsing error response: $e");
        }
      }
    } catch (e) {
      log("❌ Search error: $e");
      errorMessage.value = "Network error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get available brands from API
  Future<void> loadAvailableBrands() async {
    try {
      log("🏷️ Loading available brands...");
      
      // You can add a specific API endpoint for brands if available
      // For now, we'll use a general search to get brands
      final response = await ApiService.get('/api/offer/search?q=&limit=100', includeAuth: false);
      
      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<Map<String, dynamic>> results = [];
          
          // Handle different response formats
          if (data is List) {
            results = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data['data'] != null) {
            results = List<Map<String, dynamic>>.from(data['data']);
          }
          
          // Extract unique brands
          Set<String> brands = {};
          for (var offer in results) {
            if (offer['product_brand'] != null && offer['product_brand'].toString().isNotEmpty) {
              brands.add(offer['product_brand'].toString());
            }
          }
          
          availableBrands.value = brands.toList()..sort();
          log("✅ Loaded ${availableBrands.length} available brands");
          
        } catch (e) {
          log("❌ Error parsing brands response: $e");
        }
      }
    } catch (e) {
      log("❌ Error loading brands: $e");
    }
  }
  
  // Extract unique brands and categories from search results
  void _extractBrandsAndCategories(List<Map<String, dynamic>> results) {
    Set<String> brands = {};
    Set<String> categories = {};
    
    for (var offer in results) {
      // Extract brand
      if (offer['product_brand'] != null && offer['product_brand'].toString().isNotEmpty) {
        brands.add(offer['product_brand'].toString());
      }
      
      // Extract category (assuming offer_type as category for now)
      if (offer['offer_type'] != null && offer['offer_type'].toString().isNotEmpty) {
        categories.add(offer['offer_type'].toString());
      }
    }
    
    availableBrands.value = brands.toList()..sort();
    availableCategories.value = categories.toList()..sort();
    
    log("🏷️ Extracted brands: ${availableBrands.length}");
    log("📂 Extracted categories: ${availableCategories.length}");
  }
  
  // Clear search results
  void clearSearch() {
    searchResults.clear();
    currentQuery.value = '';
    currentBrand.value = '';
    currentCategory.value = '';
    errorMessage.value = '';
    log("🧹 Search results cleared");
  }
  
  // Add query to search history with FIFO behavior (max 5 searches)
  void _addToSearchHistory(String query) {
    // Remove if already exists to avoid duplicates
    searchHistory.remove(query);
    // Add to beginning (most recent first)
    searchHistory.insert(0, query);
    // Keep only last 5 searches (FIFO - First In, First Out)
    if (searchHistory.length > 10) {
      searchHistory.removeLast(); // Remove oldest (last in list)
    }
    // Save to preferences
    _saveSearchHistory();
  }
  
  // Load search history from preferences
  void _loadSearchHistory() async {
    try {
      await SharedPrefUtils.init();
      String? historyJson = SharedPrefUtils.getString('search_history');
      if (historyJson != null && historyJson.isNotEmpty) {
        List<dynamic> history = jsonDecode(historyJson);
        searchHistory.value = List<String>.from(history);
      }
    } catch (e) {
      log("❌ Error loading search history: $e");
    }
  }
  
  // Save search history to preferences
  void _saveSearchHistory() async {
    try {
      await SharedPrefUtils.init();
      String historyJson = jsonEncode(searchHistory.toList());
      SharedPrefUtils.setString('search_history', historyJson);
    } catch (e) {
      log("❌ Error saving search history: $e");
    }
  }
  
  // Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }
  
  // Retry search with current query and filters
  void retrySearch() {
    if (currentQuery.value.isNotEmpty) {
      searchOffers(
        currentQuery.value,
        brand: currentBrand.value.isNotEmpty ? currentBrand.value : null,
        category: currentCategory.value.isNotEmpty ? currentCategory.value : null,
      );
    }
  }
  
  // Refresh location and retry search
  Future<void> refreshLocation() async {
    log("🔄 Refreshing location...");
    await _getCurrentLocation();
  }
  void refreshLocationAndSearch() {
    _getCurrentLocation().then((_) {
      if (currentQuery.value.isNotEmpty) {
        searchOffers(
          currentQuery.value,
          brand: currentBrand.value.isNotEmpty ? currentBrand.value : null,
          category: currentCategory.value.isNotEmpty ? currentCategory.value : null,
        );
      }
    });
  }
  
  // Get formatted distance for an offer
  String getFormattedDistance(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters.isNaN || distanceMeters.isInfinite) {
      return '0m';
    }
    
    // Round to avoid floating point precision issues
    final roundedMeters = distanceMeters.roundToDouble();
    
    if (roundedMeters < 1000) {
      return '${roundedMeters.toStringAsFixed(0)}m';
    } else {
      double km = roundedMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
  
  // Check if search has results
  bool get hasResults => searchResults.isNotEmpty;
  
  // Check if currently searching
  bool get isSearching => isLoading.value;
  
  // Check if there's an error
  bool get hasError => errorMessage.value.isNotEmpty;
  
  @override
  void onClose() {
    // Clear all data when controller is disposed
    clearSearch();
    searchHistory.clear();
    log("🗑️ OfferSearchController disposed");
    super.onClose();
  }
}
