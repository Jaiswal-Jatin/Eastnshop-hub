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
  
  // Location variables
  RxDouble currentLatitude = 0.0.obs;
  RxDouble currentLongitude = 0.0.obs;
  RxBool hasLocation = false.obs;
  
  // Search history
  RxList<String> searchHistory = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    _loadSearchHistory();
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
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
      hasLocation.value = true;
      
      log("✅ Location obtained: ${position.latitude}, ${position.longitude}");
      
    } catch (e) {
      log("❌ Error getting location: $e");
      errorMessage.value = "Error getting location: $e";
      hasLocation.value = false;
    }
  }
  
  // Search offers with query and location
  Future<void> searchOffers(String query) async {
    if (query.trim().isEmpty) {
      // AppSnackBar.show(
      //   message: "Please enter a search query",
      //   type: SnackType.warning,
      // );
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentQuery.value = query.trim();
      
      // Add to search history
      _addToSearchHistory(query.trim());
      
      log("🔍 Searching offers for: '$query'");
      log("📍 Location: ${currentLatitude.value}, ${currentLongitude.value}");
      
      // Build search URL with parameters
      String searchUrl = '/api/offer/search?q=${Uri.encodeComponent(query.trim())}';
      
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
          
          if (results.isEmpty) {
            // AppSnackBar.show(
            //   message: "No offers found for '$query'",
            //   type: SnackType.info,
            // );
          }
          
        } catch (e) {
          log("❌ Error parsing search response: $e");
          errorMessage.value = "Error parsing search results";
          // AppSnackBar.show(
          //   message: "Error parsing search results. Please try again.",
          //   type: SnackType.error,
          // );
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Search failed";
          errorMessage.value = errorMsg;
          log("❌ Search API Error: $errorMsg");
          // AppSnackBar.show(
          //   message: errorMsg,
          //   type: SnackType.error,
          // );
        } catch (e) {
          errorMessage.value = "Search failed";
          log("❌ Error parsing error response: $e");
          // AppSnackBar.show(
          //   message: "Search failed. Please try again.",
          //   type: SnackType.error,
          // );
        }
      }
    } catch (e) {
      log("❌ Search error: $e");
      errorMessage.value = "Network error: ${e.toString()}";
      // AppSnackBar.show(
      //   message: "Network error. Please check your connection and try again.",
      //   type: SnackType.error,
      // );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Clear search results
  void clearSearch() {
    searchResults.clear();
    currentQuery.value = '';
    errorMessage.value = '';
  }
  
  // Add query to search history
  void _addToSearchHistory(String query) {
    // Remove if already exists
    searchHistory.remove(query);
    // Add to beginning
    searchHistory.insert(0, query);
    // Keep only last 10 searches
    if (searchHistory.length > 10) {
      searchHistory.removeLast();
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
  
  // Retry search with current query
  void retrySearch() {
    if (currentQuery.value.isNotEmpty) {
      searchOffers(currentQuery.value);
    }
  }
  
  // Refresh location and retry search
  void refreshLocationAndSearch() {
    _getCurrentLocation().then((_) {
      if (currentQuery.value.isNotEmpty) {
        searchOffers(currentQuery.value);
      }
    });
  }
  
  // Get formatted distance for an offer
  String getFormattedDistance(double? distanceMeters) {
    if (distanceMeters == null) return '0m';
    
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      double km = distanceMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
  
  // Check if search has results
  bool get hasResults => searchResults.isNotEmpty;
  
  // Check if currently searching
  bool get isSearching => isLoading.value;
  
  // Check if there's an error
  bool get hasError => errorMessage.value.isNotEmpty;
}
