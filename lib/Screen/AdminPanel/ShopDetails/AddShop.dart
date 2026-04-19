import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

import '../../../Constants/app_colors.dart';
import '../../../Controllers/shopController.dart';
import '../../../Utils/RefreshService.dart';
import '../../../Utils/SharedPrefUtils.dart';
import '../../DrawerScreen.dart';
import '../../Userpanel/Customappbar.dart';
import 'locationScreen.dart';

class AddShop extends StatefulWidget {
  const AddShop({super.key});

  @override
  State<AddShop> createState() => _AddShopState();
}

class _AddShopState extends State<AddShop> {
  final ShopController shopController = ShopController();
  final ImagePicker _picker = ImagePicker();
  String? selectedShopType;
  LatLng? selectedLocation;
  String? readableAddress;
  bool isLoading = false;
  File? selectedImage;

  // Working hours variables
  List<String> selectedDays = [];
  Map<String, List<Map<String, String>>> workingHours =
      {}; // Day -> List of time slots

  // Shop type options
  final List<String> shopTypes = [
    'Grocery Store',
    'Electronics',
    'Clothing',
    'Restaurant',
    'Pharmacy',
    'Hardware Store',
    'Beauty & Cosmetics',
    'Book Store',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _debugSharedPreferences();

    // Initialize with default working hours for Monday
    workingHours = {
      'Mon': [
        {'open': '09:00 AM', 'close': '06:00 PM'},
      ],
    };
    selectedDays = ['Mon'];
  }

  @override
  void dispose() {
    // Dispose all text controllers to prevent memory leaks
    shopController.shopNameController.dispose();
    shopController.ownerNameController.dispose();
    shopController.shopTypeController.dispose();
    shopController.pinCodeController.dispose();
    shopController.shopAddressController.dispose();
    shopController.locationController.dispose();
    shopController.photoUrlController.dispose();
    shopController.contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _debugSharedPreferences() async {
    try {
      await SharedPrefUtils.init();
      bool isLoggedIn = SharedPrefUtils.getBool('is_logged_in');
      String? userId = SharedPrefUtils.getString('user_id');
      String? userRole = SharedPrefUtils.getString('user_role');
      String? authToken = SharedPrefUtils.getString('auth_token');

      print('=== DEBUG: SharedPreferences Values ===');
      print('is_logged_in: $isLoggedIn');
      print('user_id: $userId');
      print('user_role: $userRole');
      print(
        'auth_token: ${authToken != null ? "Present (${authToken.length} chars)" : "null"}',
      );
      print('=====================================');
    } catch (e) {
      print('Debug - Error reading SharedPreferences: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Starting location request...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        if (mounted)
          _showLocationError(
            'Location services are disabled. Please enable location services.',
          );
        return;
      }
      print('✅ Location services enabled');

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📋 Permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('🔄 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('📋 Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied by user');
          if (mounted)
            _showLocationError(
              'Location permissions are denied. Please grant permission to continue.',
            );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        if (mounted)
          _showLocationError(
            'Location permissions are permanently denied. Please enable in app settings.',
          );
        return;
      }

      print('✅ Location permission granted');

      // Get current position
      print('📍 Fetching current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          selectedLocation = LatLng(position.latitude, position.longitude);
          shopController.locationController.text =
              '${position.latitude},${position.longitude}';
        });

        // Get readable address from coordinates
        await _getAddressFromLatLng(position.latitude, position.longitude);

        // Show success message
        _showLocationSuccess('Current location updated successfully');
      }

      print("✅ Current location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("❌ Error getting location: $e");
      if (mounted) _showLocationError('Error getting current location: $e');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Color(0xFF00C853),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLocationSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addShop() async {
    if (!_validateForm()) return;

    // Check if user is properly authenticated
    if (!await _checkUserAuthentication()) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');

      print('Debug - Retrieved user_id from SharedPreferences: $userIdStr');

      if (userIdStr == null || userIdStr.isEmpty) {
        print('Debug - User ID is null or empty, user not authenticated');
        _showError('User not authenticated. Please login again.');
        return;
      }

      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        print('Debug - Invalid user ID: $userIdStr, parsed as: $userId');
        _showError('Invalid user ID. Please login again.');
        return;
      }

      print('Debug - Using user ID: $userId for shop creation');
      print('Debug - User ID type: ${userId.runtimeType}');
      print('Debug - User ID value: $userId');

      // Debug form data
      print('Debug - Form data:');
      print('  shop_name: "${shopController.shopNameController.text}"');
      print('  owner_name: "${shopController.ownerNameController.text}"');
      print(
        '  shop_type: "${selectedShopType ?? shopController.shopTypeController.text}"',
      );
      print('  pin_code: "${shopController.pinCodeController.text}"');
      print('  shop_address: "${shopController.shopAddressController.text}"');
      print('  location: "${shopController.locationController.text}"');
      print('  imageFile: ${selectedImage?.path}');

      bool success = await shopController.addShop(
        shopName: shopController.shopNameController.text,
        ownerName: shopController.ownerNameController.text,
        shopType: selectedShopType ?? shopController.shopTypeController.text,
        pinCode: shopController.pinCodeController.text,
        shopAddress: shopController.shopAddressController.text,
        location: shopController.locationController.text,
        contactNumber: shopController.contactNumberController.text,
        imageFile: selectedImage,
        userId: userId,
        workingHours: workingHours.isNotEmpty ? workingHours : null,
      );

      if (success) {
        // Clear form after successful submission
        _clearForm();

        // Trigger global refresh for shops and offers
        RefreshService.to.triggerShopRefresh();

        // Show success dialog
        _showSuccessDialog();
      } else {
        // Handle shop creation failure - could be 401 or other error
        // Check if tokens were cleared (indicates auth error)
        await SharedPrefUtils.init();
        bool isStillLoggedIn = SharedPrefUtils.getBool('is_logged_in');

        if (!isStillLoggedIn) {
          // Session lost - show auth error dialog
          _showSessionExpiredDialog();
        } else {
          // Other error
          _showError(
            'Failed to add shop. Please check your information and try again.',
          );
        }
      }
    } on SocketException catch (e) {
      print("Network error adding shop: $e");
      _showError(
        'Network error. Please check your internet connection and try again.',
      );
    } on TimeoutException catch (e) {
      print("Timeout adding shop: $e");
      _showError('Request timeout. Please try again.');
    } catch (e) {
      print("Error adding shop: $e");
      _showError('Error adding shop: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    if (selectedShopType == null &&
        shopController.shopTypeController.text.isEmpty) {
      _showError('Please select shop type');
      return false;
    }
    if (shopController.pinCodeController.text.length != 6 ||
        int.tryParse(shopController.pinCodeController.text) == null) {
      _showError('Please enter a valid 6-digit pin code');
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
    String phone = shopController.contactNumberController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (phone.length < 10) {
      _showError('Please enter a valid 10-digit contact number');
      return false;
    }
    // Image upload is now optional
    return true;
  }

  void _showError(String message) {
    if (mounted) {
      // Check if it's an authentication error
      bool isAuthError =
          message.toLowerCase().contains('401') ||
          message.toLowerCase().contains('token') ||
          message.toLowerCase().contains('expired') ||
          message.toLowerCase().contains('unauthorized') ||
          message.toLowerCase().contains('authentication');

      if (isAuthError) {
        // Show authentication error dialog with login option
        _showSessionExpiredDialog();
      } else {
        // Show regular error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Color(0xFF00C853),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _showSessionExpiredDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Session Expired'),
            content: const Text(
              'Your session has expired. Please login again to continue adding a shop.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Clear form and navigate to login
                  _clearForm();
                  Get.offAllNamed('/login');
                },
                child: const Text('Login Again'),
              ),
            ],
          );
        },
      );
    }
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
                    'Shop Added Successfully!',
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
                    'Your shop has been added successfully. You can now manage your shop and add offers.',
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

  Future<bool> _checkUserAuthentication() async {
    try {
      await SharedPrefUtils.init();

      // Check if user is logged in
      bool isLoggedIn = SharedPrefUtils.getBool('is_logged_in');
      print('Debug - Is logged in: $isLoggedIn');

      if (!isLoggedIn) {
        print('Debug - User not logged in, showing error');
        _showError('Please login to add a shop.');
        return false;
      }

      // Check if user ID exists and is valid
      String? userIdStr = SharedPrefUtils.getString('user_id');
      print('Debug - Retrieved user_id from SharedPreferences: $userIdStr');

      if (userIdStr == null || userIdStr.isEmpty) {
        print('Debug - User ID is null or empty');
        _showError('User authentication data missing. Please login again.');
        return false;
      }

      int? userId = int.tryParse(userIdStr);
      print('Debug - Parsed user ID: $userId');

      if (userId == null || userId <= 0) {
        print('Debug - Invalid user ID: $userId');
        _showError('Invalid user data. Please login again.');
        return false;
      }

      print('Debug - User authentication check passed. User ID: $userId');
      return true;
    } catch (e) {
      print('Debug - Authentication check error: $e');
      _showError('Authentication check failed. Please login again.');
      return false;
    }
  }

  void _clearForm() {
    shopController.shopNameController.clear();
    shopController.ownerNameController.clear();
    shopController.shopTypeController.clear();
    shopController.pinCodeController.clear();
    shopController.shopAddressController.clear();
    shopController.locationController.clear();
    shopController.contactNumberController.clear();
    shopController.photoUrlController.clear();
    setState(() {
      selectedShopType = null;
      selectedLocation = null;
      readableAddress = null;
      selectedImage = null;
      selectedDays.clear();
      workingHours.clear();
      // Reset to default working hours
      workingHours = {
        'Mon': [
          {'open': '09:00 AM', 'close': '06:00 PM'},
        ],
      };
      selectedDays = ['Mon'];
    });
  }

  // Check if image file size is within limits
  Future<bool> _isImageSizeValid(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      // Check if file size is within 5MB limit (as per backend multer config)
      if (imageBytes.length > 5 * 1024 * 1024) {
        print('Image file too large: ${imageBytes.length} bytes (max 5MB)');
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking image size: $e');
      return false;
    }
  }

  // Check if image file type is valid (matches backend multer fileFilter)
  Future<bool> _isValidImageType(File imageFile) async {
    try {
      String fileName = imageFile.path.toLowerCase();
      String extension = fileName.split('.').last;

      // Check file extension
      List<String> validExtensions = ['png', 'jpeg', 'jpg', 'webp', 'gif'];
      if (!validExtensions.contains(extension)) {
        print('Invalid file extension: $extension');
        return false;
      }

      // Additional check: Read file header to verify it's actually an image
      List<int> fileBytes = await imageFile.readAsBytes();
      if (fileBytes.length < 4) {
        print('File too small to be a valid image');
        return false;
      }

      // Check for common image file signatures
      bool isValidSignature = false;

      // PNG signature: 89 50 4E 47
      if (fileBytes[0] == 0x89 &&
          fileBytes[1] == 0x50 &&
          fileBytes[2] == 0x4E &&
          fileBytes[3] == 0x47) {
        isValidSignature = true;
      }
      // JPEG signature: FF D8 FF
      else if (fileBytes[0] == 0xFF &&
          fileBytes[1] == 0xD8 &&
          fileBytes[2] == 0xFF) {
        isValidSignature = true;
      }
      // GIF signature: 47 49 46 38 (GIF8)
      else if (fileBytes[0] == 0x47 &&
          fileBytes[1] == 0x49 &&
          fileBytes[2] == 0x46 &&
          fileBytes[3] == 0x38) {
        isValidSignature = true;
      }
      // WEBP signature: 52 49 46 46 (RIFF) followed by WEBP
      else if (fileBytes.length >= 12 &&
          fileBytes[0] == 0x52 &&
          fileBytes[1] == 0x49 &&
          fileBytes[2] == 0x46 &&
          fileBytes[3] == 0x46 &&
          fileBytes[8] == 0x57 &&
          fileBytes[9] == 0x45 &&
          fileBytes[10] == 0x42 &&
          fileBytes[11] == 0x50) {
        isValidSignature = true;
      }

      if (!isValidSignature) {
        print('Invalid image file signature for extension: $extension');
        return false;
      }

      print('Valid image file: $fileName (extension: $extension)');
      return true;
    } catch (e) {
      print('Error checking image type: $e');
      return false;
    }
  }

  // Create a properly named file with correct extension
  Future<File?> _createProperlyNamedFile(File originalFile) async {
    try {
      // Read the original file bytes
      List<int> fileBytes = await originalFile.readAsBytes();

      // Determine the correct extension based on file signature
      String extension = 'jpg'; // default

      if (fileBytes.length >= 4) {
        // PNG signature: 89 50 4E 47
        if (fileBytes[0] == 0x89 &&
            fileBytes[1] == 0x50 &&
            fileBytes[2] == 0x4E &&
            fileBytes[3] == 0x47) {
          extension = 'png';
        }
        // JPEG signature: FF D8 FF
        else if (fileBytes[0] == 0xFF &&
            fileBytes[1] == 0xD8 &&
            fileBytes[2] == 0xFF) {
          extension = 'jpg';
        }
        // GIF signature: 47 49 46 38 (GIF8)
        else if (fileBytes[0] == 0x47 &&
            fileBytes[1] == 0x49 &&
            fileBytes[2] == 0x46 &&
            fileBytes[3] == 0x38) {
          extension = 'gif';
        }
        // WEBP signature: 52 49 46 46 (RIFF) followed by WEBP
        else if (fileBytes.length >= 12 &&
            fileBytes[0] == 0x52 &&
            fileBytes[1] == 0x49 &&
            fileBytes[2] == 0x46 &&
            fileBytes[3] == 0x46 &&
            fileBytes[8] == 0x57 &&
            fileBytes[9] == 0x45 &&
            fileBytes[10] == 0x42 &&
            fileBytes[11] == 0x50) {
          extension = 'webp';
        }
      }

      // Create a new file with proper extension
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String newFileName = 'shop_image_$timestamp.$extension';
      String tempDir = (await Directory.systemTemp).path;
      File newFile = File('$tempDir/$newFileName');

      // Write the bytes to the new file
      await newFile.writeAsBytes(fileBytes);

      print(
        'Created properly named file: ${newFile.path} (extension: $extension)',
      );
      return newFile;
    } catch (e) {
      print('Error creating properly named file: $e');
      return null;
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      print('🔄 Getting address from coordinates: $lat, $lng');
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build a more readable address
        List<String> addressParts = [];

        // Add street name if available
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }

        // Add sub-locality if available
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        // Add locality/city
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        // Add administrative area/state
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        // Add postal code if available
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        // Add country
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String address = addressParts.join(', ');

        if (mounted) {
          setState(() {
            readableAddress = address.isNotEmpty
                ? address
                : "Address not available";
            // Auto-populate the shop address field with the converted address
            if (address.isNotEmpty) {
              shopController.shopAddressController.text = address;
              // Also auto-populate pin code if available
              if (place.postalCode != null && place.postalCode!.isNotEmpty) {
                shopController.pinCodeController.text = place.postalCode!;
              }
              print('✅ Address auto-populated: $address');
              print('✅ Pin code auto-populated: ${place.postalCode}');
            }
          });
        }
      } else {
        print('❌ No placemarks found for coordinates: $lat, $lng');
        if (mounted) {
          setState(() {
            readableAddress = "Address not available";
          });
        }
      }
    } catch (e) {
      print('❌ Error getting address: $e');
      if (mounted) {
        setState(() {
          readableAddress = "Error getting address";
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        File originalFile = File(image.path);

        // Check if image size is valid
        bool isValidSize = await _isImageSizeValid(originalFile);

        // Check if file type is valid
        bool isValidType = await _isValidImageType(originalFile);

        if (isValidSize && isValidType) {
          // Create a properly named file with correct extension
          File? properlyNamedFile = await _createProperlyNamedFile(
            originalFile,
          );

          if (properlyNamedFile != null) {
            if (mounted) {
              setState(() {
                selectedImage = properlyNamedFile;
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to process image. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (!isValidSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image too large, please select an image smaller than 5MB',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else if (!isValidType) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid image format. Please select PNG, JPEG, JPG, WEBP, or GIF',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
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
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        File originalFile = File(image.path);

        // Check if image size is valid
        bool isValidSize = await _isImageSizeValid(originalFile);

        // Check if file type is valid
        bool isValidType = await _isValidImageType(originalFile);

        if (isValidSize && isValidType) {
          // Create a properly named file with correct extension
          File? properlyNamedFile = await _createProperlyNamedFile(
            originalFile,
          );

          if (properlyNamedFile != null) {
            if (mounted) {
              setState(() {
                selectedImage = properlyNamedFile;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Photo taken successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to process photo. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (!isValidSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo too large, please try again'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (!isValidType) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid image format. Please try again'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF00C853),
          size: 20,
        ),
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
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? "PM" : "AM";
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      String minuteStr = minute.toString().padLeft(2, '0');

      return "$displayHour:$minuteStr $period";
    } catch (e) {
      return time;
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF00C853),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00C853)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isFormValid() {
    return shopController.shopNameController.text.isNotEmpty &&
        shopController.ownerNameController.text.isNotEmpty &&
        (selectedShopType != null ||
            shopController.shopTypeController.text.isNotEmpty) &&
        shopController.pinCodeController.text.isNotEmpty &&
        shopController.shopAddressController.text.isNotEmpty &&
        shopController.locationController.text.isNotEmpty &&
        shopController.contactNumberController.text.isNotEmpty;
  }

  int _getTotalTimeSlots() {
    int total = 0;
    workingHours.forEach((day, slots) {
      total += slots.length;
    });
    return total;
  }

  Widget _buildTimeSlotRow(
    String day,
    int slotIndex,
    Map<String, String> slot,
    StateSetter setDialogState,
    Map<String, List<Map<String, String>>> tempWorkingHours,
    List<String> tempSelectedDays,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Open time dropdown
          Expanded(
            child: _buildTimeDropdown(
              slot['open']!,
              'Open',
              Icons.access_time,
              (newTime) {
                setDialogState(() {
                  tempWorkingHours[day]![slotIndex]['open'] = newTime;
                });
              },
            ),
          ),

          const SizedBox(width: 8),
          Text(
            'to',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),

          // Close time dropdown
          Expanded(
            child: _buildTimeDropdown(
              slot['close']!,
              'Close',
              Icons.access_time_filled,
              (newTime) {
                setDialogState(() {
                  tempWorkingHours[day]![slotIndex]['close'] = newTime;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenStreetMapPicker(initialLocation: selectedLocation),
      ),
    );
    if (result != null) {
      print(
        '🔄 New location selected from map: ${result.latitude}, ${result.longitude}',
      );

      setState(() {
        selectedLocation = result;
        shopController.locationController.text =
            '${result.latitude},${result.longitude}';
      });

      // Get readable address from new coordinates
      await _getAddressFromLatLng(result.latitude, result.longitude);

      // Show success message
      _showLocationSuccess('Location updated from map successfully');

      print('✅ Location and address updated from map selection');
    } else {
      print('❌ No location selected from map');
    }
  }

  // Reusable Gradient Button Widget
  Widget _gradientButton({
    required String text,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Clear form when back button is pressed
        _clearForm();
        return true; // Allow navigation back
      },
      child: Scaffold(
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
                      onPressed: () {
                        _clearForm(); // Clear form before navigating back
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Add Shop",
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      top: 30,
                      right: 20,
                    ),
                    child: Column(
                      children: [
                        customTextFieldWidget(
                          hintText: 'Shop Name',
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
                          hintText: 'Owner Name',
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
                          hintText: 'Contact Number',
                          controller: shopController.contactNumberController,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        SizedBox(height: 25),
                        // Shop Type Dropdown
                        Stack(
                          children: [
                            TextFormField(
                              controller: shopController.shopTypeController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9 ]'),
                                ),
                                LengthLimitingTextInputFormatter(30),
                              ],
                              decoration: InputDecoration(
                                labelText: "Shop Type",
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                                hintText: "Enter shop type",
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                ),

                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),

                            // Red * for required
                            if (shopController.shopTypeController.text.isEmpty)
                              const Positioned(
                                top: 0,
                                right: 12,
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
                        ),

                        SizedBox(height: 25),
                        customTextFieldWidget(
                          hintText: 'Pin Code',
                          controller: shopController.pinCodeController,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        SizedBox(height: 25),
                        TextField(
                          controller: shopController.shopAddressController,
                          maxLines: 2,
                          maxLength: 200,
                          onChanged: (value) {
                            setState(
                              () {},
                            ); // Trigger rebuild to update asterisk visibility
                          },
                          style: const TextStyle(
                            color: Colors.grey,
                          ), // <-- Text color set to grey
                          decoration: InputDecoration(
                            hintText: "Shop Address",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                            ), // hint text grey
                            filled: true,
                            fillColor: Colors.white, // White background
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: 14,
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
                            counterText: '', // Hide the character counter
                          ),
                        ),

                        //  SizedBox(height: 25,),
                        //  customTextFieldWidget(
                        //   hintText: 'Shop Address',
                        //   controller: shopController.shopAddressController,
                        //   isRequired: true,
                        //   maxLines: 2,
                        // ),

                        // Auto-fill indicator
                        if (readableAddress != null &&
                            shopController
                                .shopAddressController
                                .text
                                .isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '📍 Current location address auto-filled',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      shopController.shopAddressController
                                          .clear();
                                      readableAddress = null;
                                    });
                                  },
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                          ? readableAddress != null &&
                                                    readableAddress!.isNotEmpty
                                                ? readableAddress!
                                                : 'Coordinates: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}'
                                          : 'Location not selected',
                                      style: TextStyle(
                                        color: selectedLocation != null
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                        fontWeight: selectedLocation != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
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
                              if (selectedLocation != null &&
                                  readableAddress != null) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Address: $readableAddress',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showLocationPicker(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
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
                        // Image Upload Section
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Image Preview or Upload Button
                              InkWell(
                                onTap: _showImagePicker,
                                child: Container(
                                  height: selectedImage != null ? 200 : 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: selectedImage != null
                                        ? Colors.grey[100]
                                        : Colors.white,
                                  ),
                                  child: selectedImage != null
                                      ? Stack(
                                          children: [
                                            // Single Image Preview
                                            Center(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  selectedImage!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: 200,
                                                ),
                                              ),
                                            ),
                                            // Overlay with change/remove options
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed:
                                                          _showImagePicker,
                                                      tooltip: 'Change Image',
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          selectedImage = null;
                                                        });
                                                      },
                                                      tooltip: 'Remove Image',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 30,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Upload Image (Optional)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Tap to select an image',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: 10),
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
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    : _addShop,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: (isLoading || !_isFormValid())
                                        ? Colors.grey
                                        : Colors.green,
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
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Adding Shop...',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Add Shop',
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
                        SizedBox(height: 70), // Bottom space
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            inputFormatters:
                inputFormatters ??
                [LengthLimitingTextInputFormatter(200)], // default if null
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update asterisk visibility
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 14,
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
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
