
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:convert';
import 'dart:developer';

import '../../../Constants/CommonWidgets.dart';
import '../../../Constants/app_colors.dart';
import '../../../Controllers/FavoritesController.dart';
import '../../DrawerScreen.dart';
import '../Customappbar.dart';
import '../OfferDetailsPage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesController favoritesController = Get.put(FavoritesController());

  @override
  void initState() {
    super.initState();
    favoritesController.getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: Column(
        children: [
          // Header with title and refresh button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Favorite List',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: () => favoritesController.getFavorites(),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Obx(() {
              if (favoritesController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                );
              }

        if (favoritesController.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start adding items to your favorites!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Browse Offers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => favoritesController.getFavorites(),
          color: AppColors.primaryRed,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritesController.favorites.length,
            itemBuilder: (context, index) {
              final favorite = favoritesController.favorites[index];
              final itemData = favorite['item_data'] ?? favorite;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Main content
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height:120,
                              width: 110,
                              color: Colors.grey[200],
                              child: _buildFavoriteImage(itemData),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Right Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  itemData['product_name'] ??
                                      itemData['title'] ??
                                      itemData['name'] ??
                                      'Untitled Item',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 6),

                                // Discount + Prices
                                Builder(
                                  builder: (context) {
                                    String? discountLabel = itemData['discount']?.toString();
                                    // Fallback to offer_percentage if discount not provided
                                    if ((discountLabel == null || discountLabel.isEmpty) && itemData['offer_percentage'] != null) {
                                      discountLabel = "${itemData['offer_percentage']}%";
                                    }
                                    // Compute discount if still null and prices exist
                                    if ((discountLabel == null || discountLabel.isEmpty)
                                        && itemData['product_price'] != null && itemData['offer_price'] != null) {
                                      final String pp = itemData['product_price'].toString();
                                      final String op = itemData['offer_price'].toString();
                                      final double? product = double.tryParse(pp);
                                      final double? offer = double.tryParse(op);
                                      if (product != null && offer != null && product > 0 && offer <= product) {
                                        final double pct = ((product - offer) / product) * 100.0;
                                        discountLabel = "${pct.toStringAsFixed(0)}%";
                                      }
                                    }

                                    return Row(
                                      children: [
                                        if (discountLabel != null && discountLabel.isNotEmpty)
                                          Text(
                                            "$discountLabel",
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        if (itemData['product_price'] != null)
                                          Text(
                                            "₹${itemData['product_price']}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        if (itemData['offer_price'] != null)
                                          Text(
                                            "₹${itemData['offer_price']}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 6),

                                // Description
                                if (itemData['offer_description'] != null ||
                                    itemData['description'] != null)
                                  Text(
                                    itemData['offer_description'] ?? itemData['description'],
                                    style:
                                    TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                const SizedBox(height: 8),

                                // View Details Button
                                Row(
                                  children: [


                                    // Remove Favorite Button (Top-Right)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final itemData = favorite['item_data'] ?? favorite;
                                          final offerId = (favorite['offer_id']?.toString() ??
                                              itemData['id']?.toString() ??
                                              itemData['offer_id']?.toString() ??
                                              favorite['item_id']?.toString())
                                              ?.trim();

                                          if (offerId != null &&
                                              offerId.isNotEmpty &&
                                              offerId != '0') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OfferDetailsPage(offerId: offerId),
                                              ),
                                            );
                                          } else {
                                            CommonWidgets.CustomeSnackBar(
                                              title: 'Error',
                                              message: 'Offer ID not found for this item',
                                              backgroundColor: AppColors.primaryRed,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryRed,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: const Text(
                                          'View details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    InkWell(
                                      onTap: () {
                                        final favoriteId = favorite['id']?.toString();
                                        if (favoriteId != null) {
                                          favoritesController.removeFromFavoritesById(favoriteId);
                                        } else {
                                          CommonWidgets.CustomeSnackBar(
                                            title: 'Error',
                                            message: 'Cannot remove item - no valid ID found',
                                            backgroundColor: AppColors.primaryRed,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryRed,
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                )

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              );
            },
          ),
        );
      }),
    ),
        ],
      ),
    );
  }

  /// Build favorite image widget - handles JSON array photo_url properly
  Widget _buildFavoriteImage(Map<String, dynamic> itemData) {
    log("🖼️ Building favorite image for: ${itemData['product_name'] ?? 'Unknown'}");
    log("📸 Photo URL: ${itemData['photo_url']}");
    log("🖼️ Images: ${itemData['images']}");
    log("🖼️ Image: ${itemData['image']}");
    
    // First try to get image from 'images' array (if available)
    if (itemData['images'] != null && itemData['images'] is List && (itemData['images'] as List).isNotEmpty) {
      final images = itemData['images'] as List;
      final firstImageUrl = images.first.toString();
      log("✅ Using images array: $firstImageUrl");
      
      return Image.network(firstImageUrl,
fit: BoxFit.cover,);
    }
    
    // Handle photo_url JSON array string
    if (itemData['photo_url'] != null && itemData['photo_url'].toString().isNotEmpty) {
      try {
        final photoUrlString = itemData['photo_url'].toString();
        log("📸 Processing photo_url: $photoUrlString");
        
        // Check if it's a JSON array string
        if (photoUrlString.startsWith('[') && photoUrlString.endsWith(']')) {
          final List<dynamic> photoUrls = jsonDecode(photoUrlString);
          if (photoUrls.isNotEmpty) {
            final firstPhotoPath = photoUrls.first.toString();
            // Convert relative path to full URL
            final fullUrl = 'https://eastnshoptech.cloud/$firstPhotoPath';
            log("✅ Using JSON array photo_url: $fullUrl");
            
            return Image.network(fullUrl,
fit: BoxFit.cover,);
          }
        } else {
          // Single photo URL (not JSON array)
          log("✅ Using single photo_url: $photoUrlString");
          return Image.network(photoUrlString,
fit: BoxFit.cover,);
        }
      } catch (e) {
        log('❌ Error parsing photo_url: $e');
      }
    }
    
    // Fallback to image field
    if (itemData['image'] != null && itemData['image'].toString().isNotEmpty) {
      log("✅ Using fallback image field: ${itemData['image']}");
      return Image.network(itemData['image'],
fit: BoxFit.cover,);
    }
    
    // Default placeholder
    log("⚠️ No image found, using placeholder");
    return const Icon(Icons.image, size: 40, color: Colors.grey);
  }
}
