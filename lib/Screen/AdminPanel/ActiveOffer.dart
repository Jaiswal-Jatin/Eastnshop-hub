import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:dropdown_button2/dropdown_button2.dart';
import '../../Controllers/ActiveOffersController.dart';
import '../../Routes/App_Pages.dart';
import 'AdminOfferDetailsPage.dart';

import '../DrawerScreen.dart';
import '../Userpanel/Customappbar.dart';

class ActiveOffersPage extends StatefulWidget {
  final String? shopId; // Optional shop ID parameter
  
  const ActiveOffersPage({super.key, this.shopId});

  @override
  State<ActiveOffersPage> createState() => _ActiveOffersPageState();
}

class _ActiveOffersPageState extends State<ActiveOffersPage> {
  final ActiveOffersController controller = Get.put(ActiveOffersController());

  @override
  void initState() {
    super.initState();
    // If shopId is provided, fetch offers directly
    if (widget.shopId != null && widget.shopId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchOffersDirectly(widget.shopId!);
      });
    }
    // Removed automatic loading of first shop - user must select manually
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes active (e.g., returning from AddShop)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshAllData();
    });
  }

  void _clearForm() {
    setState(() {
      controller.selectedShopId.value = '';
    });
  }

  @override
  void dispose() {
    controller.selectedShopId.value = '';
    controller.clearOffers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = const Color(0xFFEA0212);

    return Scaffold(
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Active Offer",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
              SizedBox(height: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show shop selection only if no shopId is provided
                  if (widget.shopId == null) ...[
                    /// ── Shop dropdown ──────────────────────────────────────────────
                    controller.isLoadingShops.value
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text('Loading shops...'),
                                ],
                              ),
                            ),
                          )
                        : controller.shops.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                child: const Center(
                                  child: Text(
                                    'No shops found. Please contact support.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButtonFormField2<String>(
                                          alignment: AlignmentGeometry.centerLeft,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 7),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          hint: Text(
                                            'Select Shop',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                            iconSize: 24,
                                          ),
                                          buttonStyleData: const ButtonStyleData(
                                            height: 33,
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  spreadRadius: 2,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                          items: controller.shops.map((shop) {
                                            return DropdownMenuItem<String>(
                                              value: shop['id'].toString(),
                                              child: Text(
                                                shop['shop_name'] ?? 'Unknown Shop',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          value: controller.selectedShopId.value.isEmpty
                                              ? null
                                              : controller.selectedShopId.value,
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              controller.setSelectedShop(newValue, controller.getShopNameById(newValue));
                                              // Clear existing offers when shop changes
                                              controller.clearOffers();
                                              // Don't automatically load offers - wait for submit button
                                            }
                                          },
                                          onMenuStateChange: (isOpen) {
                                            if (isOpen) {
                                              HapticFeedback.lightImpact();
                                            }
                                          },
                                        ),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                    
                    // Submit button - only show when shop is selected
                    if (controller.selectedShopId.value.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: controller.isLoadingOffers.value ? null : () {
                            controller.submitAndFetchOffers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:   Color(0xFF00C853),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: controller.isLoadingOffers.value
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Loading Offers...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Load Offers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                  ] else ...[
                    // Show shop ID info when passed directly
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Showing offers for Shop ID: ${widget.shopId}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  /// ── Error Message ──────────────────────────────────────────────
                  if (controller.errorMessage.value.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  /// ── Offer grids ───────────────────────────────────────────────
                  // Only show offers if shop is selected and data has been loaded
                  if (controller.selectedShopId.value.isNotEmpty && controller.filteredOffers.isNotEmpty)
                    ...controller.filteredOffers.entries.map((entry) => _OfferSection(
                          title: entry.key,
                          offers: entry.value,
                          onEditOffer: _showEditOfferDialog,
                          onDeleteOffer: _showDeleteConfirmation,
                        ))
                  else if (controller.selectedShopId.value.isNotEmpty && !controller.isLoadingOffers.value && controller.filteredOffers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          'No offers found for this shop',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else if (controller.selectedShopId.value.isEmpty && widget.shopId == null && controller.shops.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          'Please select a shop to view offers',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }


  // Navigate to edit offer page
  void _showEditOfferDialog(BuildContext context, Map<String, dynamic> offer) async {
    // Debug logging
    print("=== EDIT OFFER NAVIGATION ===");
    print("Offer data received: $offer");
    print("Offer ID: ${offer['id']}");
    print("Offer keys: ${offer.keys.toList()}");
    
    // Navigate to edit offer page with offer data
    final result = await Get.toNamed(
      AppRoutes.editOffer,
      arguments: offer,
    );
    
    // If the edit was successful, refresh the offers
    if (result == true) {
      print("=== EDIT SUCCESSFUL, REFRESHING OFFERS ===");
      if (widget.shopId != null && widget.shopId!.isNotEmpty) {
        controller.fetchOffersDirectly(widget.shopId!);
      } else if (controller.selectedShopId.value.isNotEmpty) {
        controller.fetchOffersByShopId(controller.selectedShopId.value);
      }
    }
  }

// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded corners
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                'Make Offer Inactive',
                style: TextStyle(

                  fontWeight: FontWeight.bold,
                  fontSize: 13
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to make '
                '"${offer['product_name']?.toString() ?? 'this offer'}" inactive?',
            style: const TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.deleteOffer(offer['id'].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:Color(0xFF00C853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Make Inactive'),
            ),
          ],
        );
      },
    );
  }

}

/// ─────────────────────────────────────────────────────────────────
///  Offer section widget
/// ─────────────────────────────────────────────────────────────────
class _OfferSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> offers;
  final Function(BuildContext, Map<String, dynamic>) onEditOffer;
  final Function(BuildContext, Map<String, dynamic>) onDeleteOffer;

  const _OfferSection({
    required this.title,
    required this.offers,
    required this.onEditOffer,
    required this.onDeleteOffer,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth =
        (MediaQuery.of(context).size.width - 60) / 3; // responsive sizing

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Section Title with Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getCategoryColors(title),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getCategoryColors(title)[0].withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(title),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                // const SizedBox(width: 8),
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                //   decoration: BoxDecoration(
                //     color: Colors.white.withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Text(
                //     '${offers.length}',
                //     style: const TextStyle(
                //       fontWeight: FontWeight.bold,
                //       fontSize: 12,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Horizontal List of offers
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: offers.length,
              itemBuilder: (_, index) {
              final offer = offers[index];

              final double productPrice =
                  double.tryParse(offer['product_price'].toString()) ?? 0;
              final double offerPrice =
                  double.tryParse(offer['offer_price'].toString()) ?? 0;
              final int discount = productPrice > 0
                  ? (((productPrice - offerPrice) / productPrice) * 100).round()
                  : 0;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12), // <-- circular corners
                ),

                child: Material(

                 // elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminOfferDetailsPage(
                            offerId: offer['id'].toString(),
                            isActive: true,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Image with Hero animation
                        Stack(
                          children: [
                            Hero(
                              tag: _getFirstImageUrl(offer) ?? index.toString(),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey.shade100,
                                  child: _getFirstImageUrl(offer) != null
                                      ? Image.network(_getFirstImageUrl(offer)!,
fit: BoxFit.cover,)
                                      : _buildPlaceholderIcon(),
                                ),
                              ),
                            ),

                            /// Discount Badge
                            if (discount > 0)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "-$discount%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        /// Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Product Name
                                Text(
                                  offer['product_name']?.toString() ?? 'No Product Name',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                /// Price Info
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${offer['product_price']?.toString() ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      '₹${offer['offer_price']?.toString() ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),

                                  ],
                                ),
                               Spacer(),

                                /// Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.blue.shade700,
                                          ),
                                          onPressed: () => onEditOffer(context, offer),
                                          tooltip: "Edit",
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.highlight_remove_outlined,
                                            size: 25,
                                            color: Colors.red.shade700,
                                          ),
                                          onPressed: () => onDeleteOffer(context, offer),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable circular icon button
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  // Helper method to get the first image URL from the images array
  String? _getFirstImageUrl(Map<String, dynamic> offer) {
    // First try to get from images array
    if (offer['images'] != null && offer['images'] is List) {
      List<dynamic> images = offer['images'];
      if (images.isNotEmpty) {
        return images.first.toString();
      }
    }
    
    // Fallback to photo_url if images array is not available
    if (offer['photo_url'] != null && offer['photo_url'].toString().isNotEmpty) {
      return offer['photo_url'].toString();
    }
    
    return null;
  }

  // Get category-specific colors
  List<Color> _getCategoryColors(String category) {

        return [  Color(0xFF00C853),  Color(0xFF00C853),];

  }

  // Get category-specific icons
  IconData _getCategoryIcon(String category) {

        return Icons.whatshot;

  }
}
