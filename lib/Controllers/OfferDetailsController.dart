import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Routes/App_Pages.dart';
import '../Utils/ApiService.dart';
import '../Utils/SharedPrefUtils.dart';
import '../Utils/ImageCacheHelper.dart';

class OfferDetailsController extends GetxController {
  // Observable variables
  RxMap<String, dynamic> offerDetails = <String, dynamic>{}.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxBool isFavorite = false.obs;
  
  // Date formatters
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  // Fetch offer details by ID with retry mechanism
  Future<void> fetchOfferDetails(String offerId) async {
    await _fetchOfferDetailsWithRetry(offerId, retryCount: 0);
  }

  // Internal method with retry logic
  Future<void> _fetchOfferDetailsWithRetry(String offerId, {int retryCount = 0}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      log("=== FETCH OFFER DETAILS API CALL (Attempt ${retryCount + 1}) ===");
      log("Offer ID: $offerId");
      log("API URL: ${AppRoutes.domainName}/api/offer/$offerId");

      final response = await ApiService.get(
        '/api/offer/$offerId',
        includeAuth: false,
      );

      log("=== FETCH OFFER DETAILS RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        offerDetails.value = data;
        log("✅ Offer details loaded successfully!");
        log("Offer Data: $data");
        
        // Check if this offer is already in favorites
        await _checkFavoriteStatus();
      } else {
        dynamic errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {"message": response.body};
        }
        
        errorMessage.value = errorData['message'] ?? 'Failed to load offer details';
        log("❌ Error fetching offer details: ${response.statusCode} - ${response.body}");
        
        // AppSnackBar.show(
        //   message: errorMessage.value,
        //   type: SnackType.error,
        // );
      }
    } catch (e) {
      // Retry logic for network errors
      if (retryCount < 2 && (e.toString().contains('TimeoutException') || e.toString().contains('SocketException'))) {
        log("❌ Network error (attempt ${retryCount + 1}), retrying...");
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1))); // Exponential backoff
        await _fetchOfferDetailsWithRetry(offerId, retryCount: retryCount + 1);
        return;
      }
      
      if (e.toString().contains('TimeoutException')) {
        errorMessage.value = 'Request timed out. Please check your internet connection and try again.';
        log("❌ Timeout fetching offer details: $e");
      } else if (e.toString().contains('SocketException')) {
        errorMessage.value = 'Network error. Please check your internet connection.';
        log("❌ Network error fetching offer details: $e");
      } else {
        errorMessage.value = 'Error loading offer details: ${e.toString()}';
        log("❌ Exception fetching offer details: $e");
      }
      
      // AppSnackBar.show(
      //   message: errorMessage.value,
      //   type: SnackType.error,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  // Check if offer is already in favorites
  Future<void> _checkFavoriteStatus() async {
    try {
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        isFavorite.value = false;
        return;
      }
      
      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        isFavorite.value = false;
        return;
      }

      final offerId = offerDetails['id'];
      if (offerId == null) {
        isFavorite.value = false;
        return;
      }

      log("=== CHECKING FAVORITE STATUS ===");
      log("User ID: $userId");
      log("Offer ID: $offerId");

      final response = await ApiService.get('/api/favourites/user/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> favorites = jsonDecode(response.body);
        final isFav = favorites.any((fav) => fav['id']?.toString() == offerId.toString());
        isFavorite.value = isFav;
        log("✅ Favorite status checked: $isFav");
      } else {
        isFavorite.value = false;
        log("❌ Failed to check favorite status: ${response.statusCode}");
      }
    } catch (e) {
      isFavorite.value = false;
      if (e.toString().contains('TimeoutException')) {
        log("❌ Timeout checking favorite status: $e");
      } else if (e.toString().contains('SocketException')) {
        log("❌ Network error checking favorite status: $e");
      } else {
        log("❌ Exception checking favorite status: $e");
      }
    }
  }

  // Get formatted price with beautiful formatting
  String getFormattedPrice(dynamic price) {
    if (price == null) return '';
    try {
      final priceValue = double.tryParse(price.toString()) ?? 0;
      return _currencyFormat.format(priceValue);
    } catch (e) {
      return '';
    }
  }

  // Get original price with strikethrough styling
  String get originalPriceFormatted {
    return getFormattedPrice(offerDetails['product_price']);
  }

  // Get offer price with attractive styling
  String get offerPriceFormatted {
    return getFormattedPrice(offerDetails['offer_price']);
  }

  // Get discount percentage with attractive formatting
  String getDiscountPercentage() {
    // Prefer backend-provided discount field (e.g., "20%") if present
    final apiDiscount = offerDetails['discount']?.toString();
    if (apiDiscount != null && apiDiscount.isNotEmpty) {
      // Normalize to include % if missing
      return apiDiscount.contains('%') ? apiDiscount : '$apiDiscount%';
    }
    final originalPrice = offerDetails['product_price'];
    final offerPrice = offerDetails['offer_price'];
    
    if (originalPrice == null || offerPrice == null) return '';
    
    try {
      final original = double.tryParse(originalPrice.toString()) ?? 0;
      final offer = double.tryParse(offerPrice.toString()) ?? 0;
      
      if (original <= 0) return '';
      
      final discount = ((original - offer) / original * 100).round();
      return '${discount}%';
    } catch (e) {
      return '';
    }
  }

  // Get savings amount
  String get savingsAmount {
    final originalPrice = offerDetails['product_price'];
    final offerPrice = offerDetails['offer_price'];
    
    if (originalPrice == null || offerPrice == null) return '';
    
    try {
      final original = double.tryParse(originalPrice.toString()) ?? 0;
      final offer = double.tryParse(offerPrice.toString()) ?? 0;
      final savings = original - offer;
      
      if (savings <= 0) return '';
      
      return 'Save ${_currencyFormat.format(savings)}';
    } catch (e) {
      return '';
    }
  }

  // Check if offer is loaded
  bool get hasOfferData => offerDetails.isNotEmpty;

  // Get shop information
  Map<String, dynamic>? get shopInfo {
    return offerDetails['shop'];
  }

  // Get offer type
  String get offerType {
    return offerDetails['offer_type'] ?? '';
  }

  // Get offer design
  String get offerDesign {
    return offerDetails['offer_design'] ?? '';
  }

  // Get created date with beautiful formatting
  String get createdDate {
    final date = offerDetails['created_at'];
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        return _dateFormat.format(dateTime);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  // Get created time
  String get createdTime {
    final date = offerDetails['created_at'];
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        return _timeFormat.format(dateTime);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  // Format updated date with beautiful formatting
  String get updatedDate {
    final date = offerDetails['updated_at'];
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        return _dateFormat.format(dateTime);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  // Get updated time
  String get updatedTime {
    final date = offerDetails['updated_at'];
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        return _timeFormat.format(dateTime);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  // Get offer images list (prioritize 'images' array over 'photo_url')
  List<String> get offerImages {
    // First try to get images from 'images' array (full URLs)
    if (offerDetails['images'] != null && offerDetails['images'] is List) {
      final images = offerDetails['images'] as List;
      return images.map((img) => img.toString()).where((url) => url.isNotEmpty).toList();
    }
    
    // Fallback: try to parse photo_url JSON string
    if (offerDetails['photo_url'] != null && offerDetails['photo_url'].toString().isNotEmpty) {
      try {
        final photoUrlString = offerDetails['photo_url'].toString();
        
        // Check if it's a JSON array string
        if (photoUrlString.startsWith('[') && photoUrlString.endsWith(']')) {
          final List<dynamic> photoUrls = jsonDecode(photoUrlString);
          return photoUrls.map((path) => 'https://eastnshoptech.cloud/$path').toList();
        } else {
          // Single photo URL
          return [photoUrlString];
        }
      } catch (e) {
        log('Error parsing photo_url: $e');
      }
    }
    
    return [];
  }

  // Get primary offer image (for backward compatibility)
  String get offerImage {
    final images = offerImages;
    return images.isNotEmpty ? images.first : '';
  }

  // Get product name with validation
  String get productName {
    return offerDetails['product_name'] ?? '';
  }

  // Get product brand with validation
  String get productBrand {
    return offerDetails['product_brand'] ?? '';
  }

  // Get offer description with validation
  String get offerDescription {
    return offerDetails['offer_description'] ?? '';
  }

  // Get offer type with proper formatting
  String get offerTypeFormatted {
    final type = offerDetails['offer_type'] ?? '';
    return type.isEmpty ? '' : type.toUpperCase();
  }

  // Get offer design with proper formatting
  String get offerDesignFormatted {
    final design = offerDetails['offer_design'] ?? '';
    return design.isEmpty ? '' : design.replaceAll('-', ' ').toUpperCase();
  }

  // Check if offer is valid (has required fields)
  bool get isValidOffer {
    return productName.isNotEmpty && 
           offerPriceFormatted.isNotEmpty && 
           offerImage.isNotEmpty;
  }

  // Get offer validity status
  String get offerStatus {
    if (!isValidOffer) return 'Invalid Offer';
    if (isLoading.value) return 'Loading...';
    if (errorMessage.value.isNotEmpty) return 'Error';
    return 'Active';
  }

  // Get offer summary for sharing
  String get offerSummary {
    final name = productName;
    final price = offerPriceFormatted;
    final discount = getDiscountPercentage();
    final savings = savingsAmount;
    
    if (name.isEmpty || price.isEmpty) return '';
    
    String summary = '🌟 *Check out this amazing offer!* 🌟\n\n';
    summary += '🛍️ *Product:* $name\n';
    summary += '💰 *Price:* $price\n';
    
    if (discount.isNotEmpty) summary += '🎯 *Discount:* $discount\n';
    if (savings.isNotEmpty) summary += '💵 *You Save:* $savings\n';
    
    summary += '\n🚀 *Download EastNShop app now:*\n';
    summary += '👉 https://play.google.com/store/apps/details?id=com.eastnshop.user';
    
    return summary;
  }

  // Toggle favorite status with API call
  Future<void> toggleFavorite() async {
    try {
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

      final offerId = offerDetails['id'];
      if (offerId == null) {
        return;
      }

      if (isFavorite.value) {
        // Remove from favorites
        await _removeFromFavorites(userId, offerId);
      } else {
        // Add to favorites
        await _addToFavorites(userId, offerId);
      }
    } catch (e) {
      log("❌ Exception during favorite toggle: $e");
    }
  }

  // Add to favorites API call
  Future<void> _addToFavorites(int userId, dynamic offerId) async {
    try {
      log("=== ADD TO FAVORITES API CALL ===");
      log("User ID: $userId");
      log("Offer ID: $offerId");
      log("API URL: ${AppRoutes.domainName}/api/favourites/add");

      final requestBody = {
        "user_id": userId,
        "offer_id": offerId,
        "item_type": "offer",
        "item_data": offerDetails.value,
      };

      final response = await ApiService.post(
        '/api/favourites/add',
        body: requestBody,
      );

      log("=== ADD TO FAVORITES RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        isFavorite.value = true;
      } else {
        dynamic errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {"message": response.body};
        }
        
        // Error handling - no snack bar shown
      }
    } catch (e) {
      log("❌ Exception adding to favorites: $e");
    }
  }

  // Remove from favorites API call
  Future<void> _removeFromFavorites(int userId, dynamic offerId) async {
    try {
      log("=== REMOVE FROM FAVORITES API CALL ===");
      log("User ID: $userId");
      log("Offer ID: $offerId");
      log("API URL: ${AppRoutes.domainName}/api/favourites/remove");

      final requestBody = {
        "user_id": userId,
        "offer_id": offerId,
        "item_type": "offer",
      };

      final response = await http.delete(
        Uri.parse('${AppRoutes.domainName}/api/favourites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SharedPrefUtils.getString('auth_token') ?? ''}',
        },
        body: jsonEncode(requestBody),
      );

      log("=== REMOVE FROM FAVORITES RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        isFavorite.value = false;
      } else {
        dynamic errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {"message": response.body};
        }
        
        // Error handling - no snack bar shown
      }
    } catch (e) {
      log("❌ Exception removing from favorites: $e");
    }
  }

  // Get formatted offer ID
  String get offerIdFormatted {
    final id = offerDetails['id'];
    return id != null ? '#${id.toString().padLeft(6, '0')}' : '';
  }

  // Get shop ID formatted
  String get shopIdFormatted {
    final shopId = offerDetails['shop_id'];
    return shopId != null ? 'Shop #${shopId.toString().padLeft(4, '0')}' : '';
  }

  // Get user ID formatted
  String get userIdFormatted {
    final userId = offerDetails['user_id'];
    return userId != null ? 'User #${userId.toString().padLeft(4, '0')}' : '';
  }

  // Get time ago for created date
  String get timeAgo {
    final date = offerDetails['created_at'];
    if (date == null) return '';
    
    try {
      final createdDate = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(createdDate);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  // Share offer using system dialog to easily share image + text to WhatsApp
  Future<void> shareToWhatsApp() async {
    try {
      final shareText = offerSummary;
      if (shareText.isEmpty) {
        return;
      }

      log("=== SHARE OFFER WITH IMAGE ===");
      log("Share Text: \\n$shareText");

      final imageUrl = offerImage;
      if (imageUrl.isNotEmpty) {
        // Download and cache image first
        log("Downloading image for sharing: $imageUrl");
        final file = await ImageCacheService().downloadAndCache(imageUrl);
        
        if (file != null && await file.exists()) {
          log("Image saved at: ${file.path}");
          // Share Image + Text
          await Share.shareXFiles(
            [XFile(file.path)],
            text: shareText,
            subject: 'Check out this amazing offer!',
          );
          return;
        }
      }

      // Fallback: Share Text Only
      log("Sharing text only (no image available)");
      await Share.share(
        shareText,
        subject: 'Check out this amazing offer!',
      );

    } catch (e) {
      log("❌ Exception in shareToWhatsApp: $e");
    }
  }

  // Share to any app (generic share)
  Future<void> shareOffer() async {
    try {
      final shareText = offerSummary;
      if (shareText.isEmpty) {
        // AppSnackBar.show(
        //   message: "No offer details to share",
        //   type: SnackType.error,
        // );
        return;
      }

      log("=== SHARE OFFER ===");
      log("Share Text: $shareText");
      
      // Use share_plus for general sharing
      await Share.share(
        shareText,
        subject: 'Check out this amazing offer!',
      );
      
    } catch (e) {
      log("❌ Exception sharing offer: $e");
      // AppSnackBar.show(
      //   message: "Failed to share offer",
      //   type: SnackType.error,
      // );
    }
  }

  // Share offer with image to WhatsApp
  Future<void> shareOfferWithImage() async {
    try {
      final shareText = offerSummary;
      if (shareText.isEmpty) {
        // AppSnackBar.show(
        //   message: "No offer details to share",
        //   type: SnackType.error,
        // );
        return;
      }

      final imageUrl = offerImage;
      if (imageUrl.isEmpty) {
        // No image, just share text
        await shareToWhatsApp();
        return;
      }

      log("=== SHARE OFFER WITH IMAGE ===");
      log("Share Text: $shareText");
      log("Image URL: $imageUrl");

      // For now, share text only (image sharing requires additional setup)
      // You can implement image sharing later if needed
      await shareToWhatsApp();
      
    } catch (e) {
      log("❌ Exception sharing offer with image: $e");
      // AppSnackBar.show(
      //   message: "Failed to share offer with image",
      //   type: SnackType.error,
      // );
    }
  }

  // Open Google Maps with shop location
  Future<void> openGoogleMaps() async {
    try {
      final Map<String, dynamic>? shop = shopInfo;
      // Try explicit latitude/longitude fields first
      String? lat = (shop?['lat'] ?? offerDetails['shop_lat'] ?? offerDetails['latitude'])?.toString();
      String? lng = (shop?['lng'] ?? offerDetails['shop_lng'] ?? offerDetails['longitude'])?.toString();

      // Fallback: parse combined "location" string like "19.172975,73.008275"
      if ((lat == null || lat.isEmpty) || (lng == null || lng.isEmpty)) {
        final String? combined = (shop?['location'] ?? offerDetails['location'])?.toString();
        if (combined != null && combined.isNotEmpty && combined.contains(',')) {
          final parts = combined.split(',');
          if (parts.length >= 2) {
            lat = parts[0].trim();
            lng = parts[1].trim();
          }
        }
      }

      if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
       // AppSnackBar.show(message: 'Location not available', type: SnackType.error);
        return;
      }

      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
      //  AppSnackBar.show(message: 'Unable to open maps', type: SnackType.error);
      }
    } catch (e) {
      //AppSnackBar.show(message: 'Unable to open maps', type: SnackType.error);
    }
  }

  // Call shop phone number
  Future<void> callShop() async {
    try {
      final Map<String, dynamic>? shop = shopInfo;
      final String? phone = (shop?['phone'] ?? offerDetails['shop_phone'] ?? offerDetails['phone'])?.toString();
      if (phone == null || phone.isEmpty) {
       // AppSnackBar.show(message: 'Phone number not available', type: SnackType.error);
        return;
      }
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
     //   AppSnackBar.show(message: 'Unable to start call', type: SnackType.error);
      }
    } catch (e) {
     // AppSnackBar.show(message: 'Unable to start call', type: SnackType.error);
    }
  }

  // Get working hours data
  List<Map<String, dynamic>> get workingHours {
    final Map<String, dynamic>? shop = shopInfo;
    if (shop == null) return [];
    
    final List<dynamic>? hours = shop['working_hours'];
    if (hours == null || hours.isEmpty) return [];
    
    return hours.cast<Map<String, dynamic>>();
  }

  // Format working hours for display
  Map<String, List<String>> get formattedWorkingHours {
    final hours = workingHours;
    if (hours.isEmpty) return {};
    
    Map<String, List<String>> dayHours = {};
    
    for (var hour in hours) {
      final day = hour['day']?.toString() ?? '';
      final open = hour['open']?.toString() ?? '';
      final close = hour['close']?.toString() ?? '';
      
      if (day.isNotEmpty && open.isNotEmpty && close.isNotEmpty) {
        final formattedTime = '${_formatTime(open)} - ${_formatTime(close)}';
        
        if (dayHours.containsKey(day)) {
          dayHours[day]!.add(formattedTime);
        } else {
          dayHours[day] = [formattedTime];
        }
      }
    }
    
    return dayHours;
  }

  // Format time from HH:mm:ss to HH:mm AM/PM
  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        if (hour == 0) {
          return '12:$minute AM';
        } else if (hour < 12) {
          return '$hour:$minute AM';
        } else if (hour == 12) {
          return '12:$minute PM';
        } else {
          return '${hour - 12}:$minute PM';
        }
      }
    } catch (e) {
      // Return original time if parsing fails
    }
    return time;
  }

  // Check if shop is currently open
  bool get isShopOpen {
    final hours = workingHours;
    if (hours.isEmpty) return false;
    
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    
    for (var hour in hours) {
      final day = hour['day']?.toString() ?? '';
      final open = hour['open']?.toString() ?? '';
      final close = hour['close']?.toString() ?? '';
      
      if (day == currentDay && open.isNotEmpty && close.isNotEmpty) {
        if (currentTime.compareTo(open) >= 0 && currentTime.compareTo(close) <= 0) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  // Get shop image URL
  String get shopImageUrl {
    final Map<String, dynamic>? shop = shopInfo;
    if (shop == null) return '';
    
    final String? photoUrl = shop['photo_url']?.toString();
    if (photoUrl == null || photoUrl.isEmpty) return '';
    
    // If the URL already contains http/https, return as is
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }
    
    // Otherwise, prepend the domain
    return 'https://eastnshoptech.cloud/$photoUrl';
  }

  // Get shop address
  String get shopAddress {
    final Map<String, dynamic>? shop = shopInfo;
    if (shop == null) return '';
    
    return shop['shop_address']?.toString() ?? '';
  }
}
