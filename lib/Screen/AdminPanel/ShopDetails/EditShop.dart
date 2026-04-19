import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Controllers/shopController.dart';
import '../../../Models/ShopModel.dart';
import '../../DrawerScreen.dart';
import '../../Userpanel/Customappbar.dart';
import 'locationScreen.dart';

class UpdateShop extends StatefulWidget {
  final ShopModel shop;

  const UpdateShop({super.key, required this.shop});

  @override
  State<UpdateShop> createState() => _UpdateShopState();
}

class _UpdateShopState extends State<UpdateShop> {
  late ShopController shopController;
  late ShopListController shopListController;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  // Image handling
  File? selectedImage;
  bool isConvertingImage = false;

  // Location handling
  LatLng? selectedLocation;
  String? readableAddress;

  // Offer and Category handling
  String? selectedOfferType;
  String? selectedCategory;

  // Working hours handling
  List<String> selectedDays = [];
  Map<String, List<Map<String, String>>> workingHours =
      {}; // Day -> List of time slots

  @override
  void initState() {
    super.initState();
    shopController = Get.find<ShopController>();
    shopListController = Get.find<ShopListController>();
    // Populate form with shop data
    shopController.populateFormForEdit(widget.shop);

    // Set initial values - shop type is now handled by text field

    // Parse location if available
    if (widget.shop.location.isNotEmpty && widget.shop.location.contains(',')) {
      try {
        List<String> coords = widget.shop.location.split(',');
        if (coords.length >= 2) {
          double lat = double.parse(coords[0].trim());
          double lng = double.parse(coords[1].trim());
          selectedLocation = LatLng(lat, lng);
          _getAddressFromLatLng(lat, lng);
        }
      } catch (e) {
        print('Error parsing location: $e');
      }
    }

    // Load existing image if available
    if (widget.shop.photoUrl.isNotEmpty) {
      // For now, we'll handle this in the UI
    }

    // Load existing working hours if available
    if (widget.shop.workingHours != null &&
        widget.shop.workingHours!.isNotEmpty) {
      workingHours = {};
      selectedDays = [];

      // Parse working hours from API response format
      // API format: [{"day":"Mon","open":"09:00:00","close":"22:00:00"}, ...]
      for (var dayData in widget.shop.workingHours!) {
        String day = dayData['day'] ?? '';
        String openTime = dayData['open']?.toString() ?? '';
        String closeTime = dayData['close']?.toString() ?? '';

        if (day.isNotEmpty && openTime.isNotEmpty && closeTime.isNotEmpty) {
          // Convert 24-hour format (HH:mm:ss) to 12-hour format (HH:mm AM/PM)
          String formattedOpenTime = _convertTo12HourFormat(openTime);
          String formattedCloseTime = _convertTo12HourFormat(closeTime);

          workingHours[day] = [
            {'open': formattedOpenTime, 'close': formattedCloseTime},
          ];
          selectedDays.add(day);
        }
      }
      print('Debug - Loaded working hours: $workingHours');
      print('Debug - Selected days: $selectedDays');
    } else {
      // Initialize with default working hours if none exist
      workingHours = {
        'Mon': [
          {'open': '09:00 AM', 'close': '06:00 PM'},
        ],
      };
      selectedDays = ['Mon'];
      print('Debug - No working hours found, initialized with default');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          isConvertingImage = true;
        });

        // Simulate image processing
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          isConvertingImage = false;
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Image selected successfully'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }
    } catch (e) {
      setState(() {
        isConvertingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          isConvertingImage = true;
        });

        // Simulate image processing
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          isConvertingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo taken successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isConvertingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Select Shop Image',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Choose how you want to add your shop image',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Image selection options
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        subtitle: 'Select from Gallery',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickImage();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.camera_alt,
                        title: 'Camera',
                        subtitle: 'Take Photo',
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).pop();
                          _takePhoto();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateShop() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      bool success = await shopListController.editShop(
        shopId: widget.shop.id,
        shopName: shopController.shopNameController.text,
        ownerName: shopController.ownerNameController.text,
        shopType: shopController.shopTypeController.text,
        pinCode: shopController.pinCodeController.text,
        shopAddress: shopController.shopAddressController.text,
        location: shopController.locationController.text,
        contactNumber: shopController.contactNumberController.text,
        imageFile: selectedImage, // Pass selected image if any
        workingHours: workingHours.isNotEmpty ? workingHours : null,
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        // Show success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      print("Error updating shop: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shop: $e'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (shopController.shopNameController.text.isEmpty) {
      _showError('Please enter shop name');
      return false;
    }
    if (shopController.ownerNameController.text.isEmpty) {
      _showError('Please enter owner name');
      return false;
    }
    if (shopController.shopTypeController.text.isEmpty) {
      _showError('Please enter shop type');
      return false;
    }
    if (shopController.pinCodeController.text.isEmpty) {
      _showError('Please enter pin code');
      return false;
    }
    if (shopController.shopAddressController.text.isEmpty) {
      _showError('Please enter shop address');
      return false;
    }
    if (shopController.locationController.text.isEmpty) {
      _showError('Please select shop location');
      return false;
    }
    if (shopController.contactNumberController.text.isEmpty) {
      _showError('Please enter contact number');
      return false;
    }
    return true;
  }

  bool _isFormValid() {
    return shopController.shopNameController.text.isNotEmpty &&
        shopController.ownerNameController.text.isNotEmpty &&
        shopController.shopTypeController.text.isNotEmpty &&
        shopController.pinCodeController.text.isNotEmpty &&
        shopController.shopAddressController.text.isNotEmpty &&
        shopController.locationController.text.isNotEmpty &&
        shopController.contactNumberController.text.isNotEmpty;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF00C853)),
    );
  }

  void _showSuccessDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 15,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success Title
                  const Text(
                    'Shop Updated Successfully!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Success Message
                  const Text(
                    'Your shop has been updated successfully. You can now manage your shop and add offers.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(
                          context,
                        ).pop(); // Navigate back to home screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 3,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
          'Location services are disabled. Please enable location services.',
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        shopController.locationController.text =
            '${position.latitude},${position.longitude}';
      });

      // Get readable address from coordinates
      await _getAddressFromLatLng(position.latitude, position.longitude);

      print("Current location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("Error getting location: $e");
      _showLocationError('Error getting current location: $e');
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF00C853)),
    );
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.country ?? ''}"
                .trim();

        setState(() {
          readableAddress = address.isNotEmpty
              ? address
              : "Address not available";
          // Auto-populate the shop address field with the converted address
          if (address.isNotEmpty) {
            shopController.shopAddressController.text = address;
          }
        });
      } else {
        setState(() {
          readableAddress = "Address not available";
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        readableAddress = "Error getting address";
      });
    }
  }

  Widget _buildCurrentShopImage(String photoUrl) {
    // Check if it's a base64 image or a URL
    if (photoUrl.startsWith('data:image')) {
      // Handle base64 image
      try {
        // Extract base64 data from data URL
        String base64Data = photoUrl.split(',')[1];
        Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    } else if (photoUrl.isNotEmpty) {
      // Handle URL image
      String fullUrl = photoUrl.startsWith('http')
          ? photoUrl
          : 'https://eastnshoptech.cloud/$photoUrl';

      return Image.network(fullUrl, fit: BoxFit.cover);
    } else {
      // No image available
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.store_outlined,
              size: 32,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            width: double.infinity,
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with location icon and title
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF00C853), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Update Shop Location",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Use Current Location Section
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _getCurrentLocation();
                  },
                  child: Row(
                    children: [
                      const Text(
                        "Use Current Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.my_location, color: Colors.grey.shade600),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Map Container
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final LatLng? pickedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpenStreetMapPicker(
                          initialLocation: selectedLocation,
                        ),
                      ),
                    );
                    if (pickedLocation != null) {
                      setState(() {
                        selectedLocation = pickedLocation;
                        shopController.locationController.text =
                            '${pickedLocation.latitude},${pickedLocation.longitude}';
                      });
                      // Optionally, you can reverse geocode here to get the address
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: selectedLocation != null
                          ? Stack(
                              children: [
                                // Placeholder for map - you can replace this with actual map widget
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    image: DecorationImage(
                                      image: AssetImage("assets/img_1.png"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Red location pin
                                // Positioned(
                                //   top: 100,
                                //
                                //   right: 20,
                                //   child: Icon(
                                //     Icons.location_on,
                                //     color: Colors.red,
                                //     size: 20,
                                //   ),
                                // ),
                              ],
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 50,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No location selected',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                // New Location Section
                const Text(
                  "New Location",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // Address input field
                TextField(
                  controller: TextEditingController(
                    text: readableAddress ?? '',
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter shop address",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    suffixIcon: Icon(
                      Icons.edit,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  onChanged: (value) {
                    // Handle address input - you can add geocoding here if needed
                  },
                ),

                Spacer(),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Location is already saved in the state when selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          "Save Location",
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
              ],
            ),
          ),
        );
      },
    );
  }

  int _getTotalTimeSlots() {
    int total = 0;
    workingHours.forEach((day, slots) {
      total += slots.length;
    });
    return total;
  }

  void _showWorkingHoursDialog() {
    // Create local copies for the dialog
    List<String> tempSelectedDays = List.from(selectedDays);
    Map<String, List<Map<String, String>>> tempWorkingHours = Map.from(
      workingHours,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 15,
              backgroundColor: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    // Header with gradient background
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00C853)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Shop Working Hours",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Quick Actions Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              'All Days',
                              Icons.select_all,
                              Colors.blue,
                              tempSelectedDays.length == 7,
                              () {
                                setDialogState(() {
                                  if (tempSelectedDays.length == 7) {
                                    tempSelectedDays.clear();
                                  } else {
                                    tempSelectedDays = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun',
                                    ];
                                    for (var day in tempSelectedDays) {
                                      if (!tempWorkingHours.containsKey(day)) {
                                        tempWorkingHours[day] = [
                                          {
                                            'open': '09:00 AM',
                                            'close': '06:00 PM',
                                          },
                                        ];
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Weekdays',
                              Icons.work,
                              Colors.green,
                              tempSelectedDays.length == 5 &&
                                  !tempSelectedDays.contains('Sat') &&
                                  !tempSelectedDays.contains('Sun'),
                              () {
                                setDialogState(() {
                                  tempSelectedDays = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                  ];
                                  for (var day in tempSelectedDays) {
                                    if (!tempWorkingHours.containsKey(day)) {
                                      tempWorkingHours[day] = [
                                        {
                                          'open': '09:00 AM',
                                          'close': '06:00 PM',
                                        },
                                      ];
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              'Clear',
                              Icons.clear_all,
                              Colors.orange,
                              tempSelectedDays.isEmpty,
                              () {
                                setDialogState(() {
                                  tempSelectedDays.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Day-wise configuration list
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children:
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ].map((day) {
                              bool isOpen = tempSelectedDays.contains(day);
                              var slots =
                                  tempWorkingHours[day] ??
                                  [
                                    {'open': '09:00 AM', 'close': '06:00 PM'},
                                  ];
                              String openTime =
                                  slots.first['open'] ?? '09:00 AM';
                              String closeTime =
                                  slots.first['close'] ?? '06:00 PM';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isOpen
                                        ? Colors.green.shade200
                                        : Colors.grey.shade200,
                                    width: isOpen ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 45,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isOpen
                                                ? Colors.green.shade50
                                                : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isOpen
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            isOpen ? "Open" : "Closed",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isOpen
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: isOpen,
                                          activeColor: Colors.green,
                                          onChanged: (val) {
                                            setDialogState(() {
                                              if (val) {
                                                tempSelectedDays.add(day);
                                                if (!tempWorkingHours
                                                    .containsKey(day)) {
                                                  tempWorkingHours[day] = [
                                                    {
                                                      'open': '09:00 AM',
                                                      'close': '06:00 PM',
                                                    },
                                                  ];
                                                }
                                              } else {
                                                tempSelectedDays.remove(day);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    if (isOpen) ...[
                                      const Divider(height: 16),
                                      _buildTimeRangeSelector(
                                        openTime,
                                        closeTime,
                                        (newOpen, newClose) {
                                          setDialogState(() {
                                            tempWorkingHours[day] = [
                                              {
                                                'open': newOpen,
                                                'close': newClose,
                                              },
                                            ];
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setDialogState(() {
                                              // Enable all days
                                              tempSelectedDays = [
                                                'Mon',
                                                'Tue',
                                                'Wed',
                                                'Thu',
                                                'Fri',
                                                'Sat',
                                                'Sun',
                                              ];
                                              
                                              // Apply current time to all days
                                              for (String d in tempSelectedDays) {
                                                tempWorkingHours[d] = [
                                                  {
                                                    'open': openTime,
                                                    'close': closeTime,
                                                  },
                                                ];
                                              }
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Applied to all days of the week',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.copy_all,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          label: const Text(
                                            "Copy to all",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C853),
                                    Color(0xFF00C853),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDays = List.from(tempSelectedDays);
                                    workingHours = Map.from(tempWorkingHours);
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Save Hours",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? color : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isActive ? color : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(
    String openTime,
    String closeTime,
    Function(String, String) onTimeChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeDropdown(
            openTime,
            'Open Time',
            Icons.access_time,
            (newTime) => onTimeChanged(newTime, closeTime),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'to',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildTimeDropdown(
            closeTime,
            'Close Time',
            Icons.access_time_filled,
            (newTime) => onTimeChanged(openTime, newTime),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown(
    String currentTime,
    String label,
    IconData icon,
    Function(String) onChanged,
  ) {
    // 12-hour format time options (6 AM to 12 PM) - Fixed to avoid duplicates
    List<String> timeOptions = [
      '06:00 AM',
      '06:15 AM',
      '06:30 AM',
      '06:45 AM',
      '07:00 AM',
      '07:15 AM',
      '07:30 AM',
      '07:45 AM',
      '08:00 AM',
      '08:15 AM',
      '08:30 AM',
      '08:45 AM',
      '09:00 AM',
      '09:15 AM',
      '09:30 AM',
      '09:45 AM',
      '10:00 AM',
      '10:15 AM',
      '10:30 AM',
      '10:45 AM',
      '11:00 AM',
      '11:15 AM',
      '11:30 AM',
      '11:45 AM',
      '12:00 PM',
      '12:15 PM',
      '12:30 PM',
      '12:45 PM',
      '01:00 PM',
      '01:15 PM',
      '01:30 PM',
      '01:45 PM',
      '02:00 PM',
      '02:15 PM',
      '02:30 PM',
      '02:45 PM',
      '03:00 PM',
      '03:15 PM',
      '03:30 PM',
      '03:45 PM',
      '04:00 PM',
      '04:15 PM',
      '04:30 PM',
      '04:45 PM',
      '05:00 PM',
      '05:15 PM',
      '05:30 PM',
      '05:45 PM',
      '06:00 PM',
      '06:15 PM',
      '06:30 PM',
      '06:45 PM',
      '07:00 PM',
      '07:15 PM',
      '07:30 PM',
      '07:45 PM',
      '08:00 PM',
      '08:15 PM',
      '08:30 PM',
      '08:45 PM',
      '09:00 PM',
      '09:15 PM',
      '09:30 PM',
      '09:45 PM',
      '10:00 PM',
      '10:15 PM',
      '10:30 PM',
      '10:45 PM',
      '11:00 PM',
      '11:15 PM',
      '11:30 PM',
      '11:45 PM',
    ];

    // Ensure currentTime is valid, default to 09:00 AM if not
    String validCurrentTime = timeOptions.contains(currentTime)
        ? currentTime
        : '09:00 AM';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: validCurrentTime,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),

          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00C853), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        items: timeOptions.map((String time) {
          String displayTime = _formatTimeForDisplay(time);
          return DropdownMenuItem<String>(
            value: time,
            child: Text(
              displayTime,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF00C853), size: 20),
        iconSize: 20,
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  String _formatTimeForDisplay(String time) {
    try {
      List<String> parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1].split(' ')[0]);

      String period = time.toUpperCase().contains('PM') || hour >= 12 ? "PM" : "AM";
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      // Always pad with leading zero to match timeOptions
      String hourStr = displayHour.toString().padLeft(2, '0');
      String minuteStr = minute.toString().padLeft(2, '0');

      return "$hourStr:$minuteStr $period";
    } catch (e) {
      return time;
    }
  }

  String _convertTo12HourFormat(String time) {
    if (time.isEmpty) return '';
    
    // Normalize if it already contains AM or PM (ensure leading zero)
    if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
      try {
        final parts = time.trim().split(':');
        final hour = parts[0].padLeft(2, '0');
        return "$hour:${parts[1].toUpperCase()}";
      } catch (e) {
        return time.toUpperCase();
      }
    }

    try {
      // Handle different time formats from API (HH:mm:ss)
      String cleanTime = time.trim();
      
      if (cleanTime.split(':').length == 3) {
        List<String> parts = cleanTime.split(':');
        cleanTime = "${parts[0]}:${parts[1]}";
      }
      
      List<String> parts = cleanTime.split(':');
      if (parts.length < 2) return time;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? "PM" : "AM";
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      // Always pad with leading zero to match dropdown options
      String hourStr = displayHour.toString().padLeft(2, '0');
      String minuteStr = minute.toString().padLeft(2, '0');
      
      return "$hourStr:$minuteStr $period";
    } catch (e) {
      print('Error converting time format: $time - $e');
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(), // Your drawer widget
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Edit Shop",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 30, right: 20),
                  child: Column(
                    children: [
                      customTextFieldWidget(
                        hintText: 'Enter shop name',
                        controller: shopController.shopNameController,
                        isRequired: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]'),
                          ),
                          LengthLimitingTextInputFormatter(100),
                        ],
                      ),
                      SizedBox(height: 25),

                      customTextFieldWidget(
                        hintText: 'Enter owner name',
                        controller: shopController.ownerNameController,
                        isRequired: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]'),
                          ),
                          LengthLimitingTextInputFormatter(50),
                        ],
                      ),
                      SizedBox(height: 25),

                      customTextFieldWidget(
                        hintText: 'Enter contact number',
                        controller: shopController.contactNumberController,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      SizedBox(height: 25),

                      customTextFieldWidget(
                        hintText: 'Enter shop type',
                        controller: shopController.shopTypeController,
                        isRequired: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]'),
                          ),
                          LengthLimitingTextInputFormatter(20),
                        ],
                      ),
                      SizedBox(height: 25),

                      customTextFieldWidget(
                        hintText: 'Enter pin code',
                        controller: shopController.pinCodeController,
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                      ),
                      SizedBox(height: 25),

                      customTextFieldWidget(
                        hintText: 'Enter shop address',
                        controller: shopController.shopAddressController,
                        isRequired: true,
                        maxLines: 1,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      ),
                      SizedBox(height: 25),
                      // Location Display
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedLocation != null
                                        ? 'Location: ${readableAddress ?? "Address not available"}'
                                        : 'Location not selected',
                                    style: TextStyle(
                                      color: selectedLocation != null
                                          ? Colors.grey
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _getCurrentLocation,
                                  icon: Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Get Current Location',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _showLocationPicker(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Change Shop Location",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 25),
                      // Current Image Display
                      if (widget.shop.photoUrl.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Current Shop Image:",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 200,
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildCurrentShopImage(
                                    widget.shop.photoUrl,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Image Upload Section
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  if (selectedImage != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF00C853,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              0xFF00C853,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: const Text(
                                          "Remove",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF00C853),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Selected Image Preview
                            if (selectedImage != null)
                              Container(
                                height: 200,
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImage!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            // Add Image Button
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                onTap: _showImagePicker,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedImage != null
                                            ? "Change Image"
                                            : "Add Shop Image",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Info message
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Select a new image to replace the current one. Leave empty to keep the existing image.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 25),
                      // Working Hours Button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: _showWorkingHoursDialog,
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  color: Color(0xFF00C853),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Shop Working Hours',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        selectedDays.isEmpty
                                            ? 'Tap to set working hours'
                                            : '${selectedDays.length} days selected - ${_getTotalTimeSlots()} time slots',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      // Show working hours summary
                                      // if (selectedDays.isNotEmpty && workingHours.isNotEmpty) ...[
                                      //   SizedBox(height: 2),
                                      //   Text(
                                      //     'Days: ${selectedDays.join(', ')}',
                                      //     style: TextStyle(
                                      //       color: Colors.blue,
                                      //       fontSize: 10,
                                      //     ),
                                      //   ),
                                      //   SizedBox(height: 2),
                                      //   Text(
                                      //     'Hours: ${workingHours.values.first.first['open']} - ${workingHours.values.first.first['close']}',
                                      //     style: TextStyle(
                                      //       color: Colors.green,
                                      //       fontSize: 10,
                                      //     ),
                                      //   ),
                                      // ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: (isLoading || !_isFormValid())
                                  ? null
                                  : _updateShop,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: (isLoading || !_isFormValid())
                                      ? Colors.grey
                                      : Color(0xFF00C853),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                              'Updating Shop...',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Update Shop',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 100), // Bottom space
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget customTextFieldWidget({
    required String hintText,
    TextEditingController? controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Stack(
      children: [
        SizedBox(
          height: 47,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.grey),
            inputFormatters:
                inputFormatters ??
                (maxLength != null
                    ? [LengthLimitingTextInputFormatter(maxLength)]
                    : null), // 👈 apply only if provided
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 7,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
        ),

        // Asterisk in top-right if required AND field is empty
        if (isRequired && (controller?.text.isEmpty ?? true))
          const Positioned(
            top: 2,
            right: 15,
            child: Text(
              '*',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF00C853),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
