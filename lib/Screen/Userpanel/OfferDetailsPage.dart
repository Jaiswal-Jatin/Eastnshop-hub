import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/OfferDetailsController.dart';
import '../../Utils/SharedPrefUtils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../DrawerScreen.dart';
import 'Customappbar.dart';

class OfferDetailsPage extends StatefulWidget {
  final String offerId;

  const OfferDetailsPage({super.key, required this.offerId});

  @override
  State<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    final OfferDetailsController controller = Get.put(OfferDetailsController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchOfferDetails(widget.offerId);
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startImageTimer(int imageCount) {
    // Cancel any existing timer before starting a new one
    _imageTimer?.cancel();

    if (imageCount > 1) {
      _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) return;

        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % imageCount;
        });

        _imageController.animateToPage(
          _currentImageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // Stop auto-sliding image timer
  void _stopImageTimer() {
    _imageTimer?.cancel();
  }

  // Restart auto-sliding image timer
  void _restartImageTimer(int imageCount) {
    _stopImageTimer();
    _startImageTimer(imageCount);
  }

  @override
  Widget build(BuildContext context) {
    final OfferDetailsController controller = Get.put(OfferDetailsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchOfferDetails(widget.offerId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!controller.hasOfferData) {
          return const Center(child: Text('No offer data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Offer Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Image Carousel with multiple images
              Builder(
                builder: (_) {
                  final images = controller.offerImages;
                  if (images.isEmpty) {
                    // Fallback to local asset when no images available
                    return Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/img.png', fit: BoxFit.cover),
                    );
                  }

                  return Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Image carousel
                        PageView.builder(
                          controller: _imageController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                            // Restart timer when user manually changes page
                            _restartImageTimer(images.length);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        // Start auto-sliding timer for images (only if <= 2 images)
                        Builder(
                          builder: (context) {
                            // Start timer when images are available and count is <= 2
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _startImageTimer(images.length);
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                        // Image indicators (only show if more than 1 image)
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: _currentImageIndex == index ? 12 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.red
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Image counter (only show if more than 1 image)
                        if (images.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Product Name
              if (controller.productName.isNotEmpty)
                Text(
                  controller.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 8),

              // Product Brand
              if (controller.productBrand.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.branding_watermark,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.productBrand,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Offer Type Badge
              if (controller.offerType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.offerType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Discount and Prices
              Row(
                children: [
                  if (controller.getDiscountPercentage().isNotEmpty) ...[
                    const Icon(
                      Icons.arrow_downward,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.getDiscountPercentage(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  if (controller.originalPriceFormatted.isNotEmpty)
                    Text(
                      controller.originalPriceFormatted,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    controller.offerPriceFormatted,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Savings amount
              if (controller.savingsAmount.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    controller.savingsAmount,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Offer ID and Created Date
              // Row(
              //   children: [
              //     if (controller.offerIdFormatted.isNotEmpty) ...[
              //       const Icon(Icons.tag, color: Colors.grey, size: 16),
              //       const SizedBox(width: 4),
              //       Text(
              //         controller.offerIdFormatted,
              //         style: const TextStyle(
              //           color: Colors.grey,
              //           fontSize: 12,
              //           fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ],
              //     if (controller.createdDate.isNotEmpty) ...[
              //       const SizedBox(width: 16),
              //       const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
              //       const SizedBox(width: 4),
              //       Text(
              //         controller.createdDate,
              //         style: const TextStyle(
              //           color: Colors.grey,
              //           fontSize: 12,
              //           fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ],
              //   ],
              // ),
              //
              // const SizedBox(height: 8),

              // Description
              if (controller.offerDescription.isNotEmpty)
                Text(
                  controller.offerDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),

              const SizedBox(height: 20),

              // Shop Info
              if (controller.shopInfo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Image and Name Row
                    Row(
                      children: [
                        // Shop Image
                        if (controller.shopImageUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              controller.shopImageUrl,
                            ),
                            child: Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                controller.shopImageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        // Shop Name
                        Expanded(
                          child: Text(
                            controller.shopInfo!['shop_name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(controller.shopInfo!['owner_name'] ?? ''),
                      ],
                    ),

                    const SizedBox(height: 8),
                    // Shop Address
                    if (controller.shopAddress.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.shopAddress,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),
                    // Shop's contact number (click to call)
                    Builder(
                      builder: (context) {
                        final String shopPhone =
                            controller.shopInfo!['number'] ?? '';
                        if (shopPhone.isEmpty) return const SizedBox.shrink();
                        return InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:$shopPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Column(
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.phone,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Call Shop",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.contact_phone,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    shopPhone,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    // Working Hours Button
                    Builder(
                      builder: (context) {
                        final workingHours = controller.formattedWorkingHours;
                        if (workingHours.isEmpty)
                          return const SizedBox.shrink();

                        return InkWell(
                          onTap: () =>
                              _showWorkingHoursDialog(context, controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.blue[600],
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Working Hours',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        controller.isShopOpen
                                            ? 'Open Now'
                                            : 'Closed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: controller.isShopOpen
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Get Shop Direction Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.openGoogleMaps(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Get Shop Direction",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Share and Favorite Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Share with",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => controller.shareToWhatsApp(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green[50],
                          ),
                          child: Image.asset(
                            "assets/whatsapp.png",
                            height: 28,
                            width: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "Add to Favorite",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => InkWell(
                          onTap: () => controller.toggleFavorite(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: controller.isFavorite.value
                                  ? Colors.red[50]
                                  : Colors.grey[50],
                              border: Border.all(
                                color: controller.isFavorite.value
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              controller.isFavorite.value
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: controller.isFavorite.value
                                  ? Colors.red
                                  : Colors.grey,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  // Show working hours dialog
  void _showWorkingHoursDialog(
    BuildContext context,
    OfferDetailsController controller,
  ) {
    final workingHours = controller.formattedWorkingHours;
    if (workingHours.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: double.infinity,
            height: 450,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with clock icon and title
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Shop Working Hours",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current status badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: controller.isShopOpen
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.isShopOpen
                          ? Colors.green[300]!
                          : Colors.red[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: controller.isShopOpen
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          controller.isShopOpen
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: controller.isShopOpen
                              ? Colors.green[600]
                              : Colors.red[600],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isShopOpen
                            ? 'Currently Open'
                            : 'Currently Closed',
                        style: TextStyle(
                          color: controller.isShopOpen
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Working Hours List
                Expanded(
                  child: ListView.builder(
                    itemCount: workingHours.length,
                    itemBuilder: (context, index) {
                      final entry = workingHours.entries.elementAt(index);
                      final day = entry.key;
                      final times = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day header
                                // Row(
                                //   children: [
                                //     Text(
                                //       day,
                                //       style: TextStyle(
                                //         fontWeight: FontWeight.bold,
                                //         fontSize: 16,
                                //         color: Colors.black87,
                                //       ),
                                //     ),
                                //     Spacer(),
                                //     // Container(
                                //     //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                //     //   decoration: BoxDecoration(
                                //     //     color: Colors.red,
                                //     //     borderRadius: BorderRadius.circular(4),
                                //     //   ),
                                //     //   child: Text(
                                //     //     '${times.length}',
                                //     //     style: TextStyle(
                                //     //       color: Colors.white,
                                //     //       fontSize: 12,
                                //     //       fontWeight: FontWeight.bold,
                                //     //     ),
                                //     //   ),
                                //     // ),
                                //   ],
                                // ),
                                SizedBox(height: 8),
                                // Time slots for this day
                                ...times
                                    .map(
                                      (time) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              time,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show full-screen image viewer
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}

// Full-screen image viewer widget
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late TransformationController _transformationController;
  late InteractiveViewer _interactiveViewer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _interactiveViewer = InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.network(widget.imageUrl, fit: BoxFit.contain),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shop Image', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity();
              });
            },
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: Center(child: _interactiveViewer),
    );
  }
}
