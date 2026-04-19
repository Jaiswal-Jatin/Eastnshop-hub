import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../Constants/CommonWidgets.dart';
import '../Constants/app_colors.dart';
import '../Routes/App_Pages.dart';
import '../Utils/SharedPrefUtils.dart';

class FavoritesController extends GetxController {
  RxList<Map<String, dynamic>> favorites = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getUserId();
  }

  Future<void> getUserId() async {
    await SharedPrefUtils.init();
    final storedUserId = SharedPrefUtils.getString('user_id') ?? '';
    userId.value = storedUserId;
    log('Retrieved user ID from SharedPreferences: $storedUserId');
    if (userId.value.isNotEmpty && userId.value != '0') {
      await getFavorites();
    } else {
      log('User ID is empty or 0, not fetching favorites');
    }
  }

  Future<void> getFavorites() async {
    if (userId.value.isEmpty) {
      CommonWidgets.CustomeSnackBar(
        title: 'Error',
        message: 'User not logged in',
        backgroundColor: AppColors.primaryRed,
      );
      return;
    }

    log('Fetching favorites for User ID: ${userId.value}');
    isLoading.value = true;
    
    try {
      final response = await http.get(
        Uri.parse('${AppRoutes.domainName}/api/favourites/user/${userId.value}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SharedPrefUtils.getString('auth_token') ?? ''}',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Raw favorites API response: $data');
        
        if (data is List) {
          favorites.value = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          favorites.value = List<Map<String, dynamic>>.from(data['data']);
        } else {
          favorites.value = [];
        }
        log('Favorites loaded: ${favorites.length} items');
        if (favorites.isNotEmpty) {
          log('First favorite item structure: ${favorites.first}');
          // Log the specific fields we need
          final firstItem = favorites.first;
          log('Favorite ID: ${firstItem['id']}');
          log('User ID: ${firstItem['user_id']}');
          log('Product Name: ${firstItem['product_name']}');
        }
      } else {
        log('Error loading favorites: ${response.statusCode} - ${response.body}');
        favorites.value = [];

      }
    } catch (e) {
      favorites.value = [];
      if (e.toString().contains('TimeoutException')) {
        log('Timeout loading favorites: $e');

      } else if (e.toString().contains('SocketException')) {
        log('Network error loading favorites: $e');

      } else {
        log('Exception loading favorites: $e');

      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToFavorites(Map<String, dynamic> item) async {
    if (userId.value.isEmpty) {

      return;
    }

    final offerId = int.tryParse(item['id']?.toString() ?? item['item_id']?.toString() ?? '0') ?? 0;
    if (offerId == 0) {

      return;
    }

    log('Adding to favorites - User ID: ${userId.value}, Offer ID: $offerId');

    try {
      final response = await http.post(
        Uri.parse('${AppRoutes.domainName}/api/favourites/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SharedPrefUtils.getString('auth_token') ?? ''}',
        },
        body: jsonEncode({
          'user_id': int.parse(userId.value),
          'offer_id': offerId,
          'item_type': item['type'] ?? 'offer',
          'item_data': item,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        await getFavorites(); // Refresh the list
      } else {
        log('Error adding to favorites: ${response.statusCode} - ${response.body}');

      }
    } catch (e) {
      log('Exception adding to favorites: $e');

    }
  }

  Future<void> removeFromFavorites(String offerId) async {
    if (userId.value.isEmpty) {

      return;
    }

    final parsedOfferId = int.tryParse(offerId) ?? 0;
    if (parsedOfferId == 0) {

      return;
    }

    log('Removing from favorites - User ID: ${userId.value}, Offer ID: $parsedOfferId');

    final requestBody = {
      'user_id': int.parse(userId.value),
      'offer_id': parsedOfferId,
    };
    
    log('Remove API Request Body: ${jsonEncode(requestBody)}');
    log('Remove API URL: ${AppRoutes.domainName}/api/favourites/remove');

    try {
      final response = await http.delete(
        Uri.parse('${AppRoutes.domainName}/api/favourites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SharedPrefUtils.getString('auth_token') ?? ''}',
        },
        body: jsonEncode(requestBody),
      );

      log('Remove API Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {

        await getFavorites(); // Refresh the list
      } else {
        log('Error removing from favorites: ${response.statusCode} - ${response.body}');
        
        // Try to parse error message from response
        String errorMessage = 'Failed to remove from favorites (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Use default error message
        }
        

      }
    } catch (e) {
      log('Exception removing from favorites: $e');

    }
  }

  bool isFavorite(String offerId) {
    return favorites.any((favorite) => 
      favorite['id']?.toString() == offerId ||
      favorite['offer_id']?.toString() == offerId || 
      favorite['item_id']?.toString() == offerId);
  }

  String? getOfferId(String itemId) {
    final favorite = favorites.firstWhereOrNull((favorite) => 
      favorite['id']?.toString() == itemId ||
      favorite['item_id']?.toString() == itemId);
    return favorite?['id']?.toString() ?? favorite?['offer_id']?.toString() ?? favorite?['item_id']?.toString();
  }

  // Method to remove by favorite record ID using the correct API
  Future<void> removeFromFavoritesById(String favoriteId) async {
    if (userId.value.isEmpty) {

      return;
    }

    // Find the favorite item to get the offer_id
    final favorite = favorites.firstWhereOrNull((fav) => fav['id']?.toString() == favoriteId);
    if (favorite == null) {

      return;
    }

    // Extract offer_id from the favorite item
    // The API expects the favorite item's id as the offer_id
    final offerId = favorite['id']?.toString() ?? '0';
    
    log('Removing favorite by ID - User ID: ${userId.value}, Favorite ID: $favoriteId, Offer ID: $offerId');
    log('Favorite item user_id: ${favorite['user_id']}');

    // Ensure we have a valid user ID
    if (userId.value.isEmpty || userId.value == '0') {

      return;
    }
    
    final requestBody = {
      'user_id': int.parse(userId.value),
      'offer_id': int.tryParse(offerId) ?? 0,
    };
    
    log('Remove API Request Body: ${jsonEncode(requestBody)}');
    log('Remove API URL: ${AppRoutes.domainName}/api/favourites/remove');

    try {
      final response = await http.delete(
        Uri.parse('${AppRoutes.domainName}/api/favourites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SharedPrefUtils.getString('auth_token') ?? ''}',
        },
        body: jsonEncode(requestBody),
      );

      log('Remove API Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {

        await getFavorites(); // Refresh the list
      } else {
        log('Error removing favorite: ${response.statusCode} - ${response.body}');
        
        // Try to parse error message from response
        String errorMessage = 'Failed to remove from favorites (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Use default error message
        }
        

      }
    } catch (e) {
      log('Exception removing favorite: $e');

    }
  }
}
