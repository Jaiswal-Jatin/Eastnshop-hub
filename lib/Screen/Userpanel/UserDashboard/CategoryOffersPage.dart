
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../Controllers/FavoritesController.dart';
import '../../DrawerScreen.dart';
import '../Customappbar.dart';
import '../OfferDetailsPage.dart';

class CategoryOffersPage extends StatefulWidget {
  final String category;
  final String categoryTitle;

  const CategoryOffersPage({
    super.key,
    required this.category,
    required this.categoryTitle,
  });

  @override
  State<CategoryOffersPage> createState() => _CategoryOffersPageState();
}

class _CategoryOffersPageState extends State<CategoryOffersPage> {
  final FavoritesController favoritesController = Get.find<FavoritesController>();
  List<Map<String, dynamic>> offers = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  final int limit = 10;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMoreData) {
        _loadMoreOffers();
      }
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://eastnshoptech.cloud/api/offer/category/${widget.category}?limit=$limit&offset=0'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Category API Response for ${widget.category}: $data');
        if (data is Map<String, dynamic>) {
          // Handle the category-based response format
          List<Map<String, dynamic>> allOffers = [];
          
          // Extract offers from the category-based response
          data.forEach((category, categoryOffers) {
            if (categoryOffers is List) {
              for (var offer in categoryOffers) {
                if (offer is Map<String, dynamic>) {
                  // Add the category information to each offer
                  offer['category'] = category;
                  allOffers.add(offer);
                }
              }
            }
          });
          
          setState(() {
            offers = allOffers;
            isLoading = false;
            currentPage = 0; // Start from page 0
            hasMoreData = allOffers.length >= limit;
          });
        } else if (data is List) {
          // Handle direct array response format
          setState(() {
            offers = List<Map<String, dynamic>>.from(data);
            isLoading = false;
            currentPage = 0; // Start from page 0
            hasMoreData = data.length >= limit;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = 'Invalid response format';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Failed to load offers: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading offers: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreOffers() async {
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Increment page first, then calculate offset
      currentPage++;
      final offset = currentPage * limit;
      final response = await http.get(
        Uri.parse('https://eastnshoptech.cloud/api/offer/category/${widget.category}?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          // Handle the category-based response format
          List<Map<String, dynamic>> newOffers = [];
          
          // Extract offers from the category-based response
          data.forEach((category, categoryOffers) {
            if (categoryOffers is List) {
              for (var offer in categoryOffers) {
                if (offer is Map<String, dynamic>) {
                  // Add the category information to each offer
                  offer['category'] = category;
                  newOffers.add(offer);
                }
              }
            }
          });
          
          setState(() {
            offers.addAll(newOffers);
            isLoading = false;
            hasMoreData = newOffers.length >= limit;
          });
        } else if (data is List) {
          // Handle direct array response format
          setState(() {
            offers.addAll(List<Map<String, dynamic>>.from(data));
            isLoading = false;
            hasMoreData = data.length >= limit;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          hasMoreData = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasMoreData = false;
      });
    }
  }

  Future<void> _refreshOffers() async {
    setState(() {
      offers.clear();
      currentPage = 0;
      hasMoreData = true;
    });
    await _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: Column(
        children: [
          // Custom header row
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.categoryTitle} Offers',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: _refreshOffers,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Body content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshOffers,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (hasError) {
      return _buildErrorState();
    }

    if (offers.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (offers.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100,left: 12,right: 12,top: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: offers.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == offers.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final offer = offers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Offers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshOffers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Offers Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No ${widget.categoryTitle.toLowerCase()} offers found at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshOffers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final offerId = offer['id']?.toString() ?? '0';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OfferDetailsPage(offerId: offerId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and Heart icon row
                Stack(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildOfferImage(offer),
                    ),
                    // Heart icon positioned at top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Obx(() => GestureDetector(
                        onTap: () {
                          final itemData = {
                            'id': offerId,
                            'offer_id': int.tryParse(offerId) ?? 0,
                            'title': offer['product_name'] ?? 'Unknown Product',
                            'discount': offer['offer_type'] ?? 'Offer',
                            'image': offer['photo_url'],
                            'type': 'offer',
                          };

                          if (favoritesController.isFavorite(offerId)) {
                            favoritesController.removeFromFavorites(offerId);
                          } else {
                            favoritesController.addToFavorites(itemData);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            favoritesController.isFavorite(offerId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: favoritesController.isFavorite(offerId)
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Product name
                Text(
                  offer['product_name'] ?? 'Unknown Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Discount badge
                Builder(
                  builder: (context) {
                    String? discountLabel = offer['discount']?.toString();
                    if ((discountLabel == null || discountLabel.isEmpty)
                        && offer['product_price'] != null && offer['offer_price'] != null) {
                      final String pp = offer['product_price'].toString();
                      final String op = offer['offer_price'].toString();
                      final double? product = double.tryParse(pp);
                      final double? offerP = double.tryParse(op);
                      if (product != null && offerP != null && product > 0 && offerP <= product) {
                        final double pct = ((product - offerP) / product) * 100.0;
                        discountLabel = "${pct.toStringAsFixed(0)}%";
                      }
                    }
                    if (discountLabel == null || discountLabel.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Text(
                        '↓$discountLabel',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // Price
                if (offer['offer_price'] != null && offer['product_price'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${offer['offer_price']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '₹${offer['product_price']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferImage(Map<String, dynamic> offer) {
    // First try to get image from 'images' array (full URLs)
    if (offer['images'] != null && offer['images'] is List && (offer['images'] as List).isNotEmpty) {
      final images = offer['images'] as List;
      final firstImageUrl = images.first.toString();
      
      return Image.network(firstImageUrl,
width: double.infinity,
        height: 120,
        fit: BoxFit.cover,);
    }
    
    // Fallback: try to parse photo_url JSON string
    if (offer['photo_url'] != null && offer['photo_url'].toString().isNotEmpty) {
      try {
        final photoUrlString = offer['photo_url'].toString();
        
        // Check if it's a JSON array string
        if (photoUrlString.startsWith('[') && photoUrlString.endsWith(']')) {
          final List<dynamic> photoUrls = jsonDecode(photoUrlString);
          if (photoUrls.isNotEmpty) {
            final firstPhotoPath = photoUrls.first.toString();
            // Convert relative path to full URL
            final fullUrl = 'https://eastnshoptech.cloud/$firstPhotoPath';
            
            return Image.network(fullUrl,
width: double.infinity,
              height: 120,
              fit: BoxFit.cover,);
          }
        } else {
          // Single photo URL
          return Image.network(photoUrlString,
width: double.infinity,
            height: 120,
            fit: BoxFit.cover,);
        }
      } catch (e) {
        print('Error parsing photo_url: $e');
      }
    }
    
    // Default placeholder
    return Container(
      width: double.infinity,
      height: 120,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 32, color: Colors.grey),
    );
  }
}
