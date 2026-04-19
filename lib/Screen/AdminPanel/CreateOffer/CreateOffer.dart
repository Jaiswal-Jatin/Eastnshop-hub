
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:io';

import '../../../Constants/CommonWidgets.dart';
import '../../../Constants/app_colors.dart';
import '../../../Controllers/offerController.dart';
import '../../DrawerScreen.dart';
import '../../Userpanel/Customappbar.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final OfferController offerController = Get.put(OfferController());
  final ImagePicker _picker = ImagePicker();
  List<PlatformFile> pickedFiles = [];
  List<File> selectedImages = [];
  List<String> imageUrls = [];
  bool isUploadingImage = false;

  // ✅ Define reusable border
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.grey),
  );

  // Product brand controller
  late TextEditingController productBrandController;

  @override
  void initState() {
    super.initState();
    productBrandController = TextEditingController();
    offerController.fetchShops();
  }

  @override
  void dispose() {
    // Avoid calling setState during dispose; just clear state directly
    offerController.clearForm();
    productBrandController.dispose();
    selectedImages.clear();
    imageUrls.clear();
    pickedFiles.clear();
    isUploadingImage = false;
    super.dispose();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        // Limit to 5 images maximum
        int remainingSlots = 5 - pickedFiles.length;
        int filesToAdd = result.files.length > remainingSlots ? remainingSlots : result.files.length;
        
        for (int i = 0; i < filesToAdd; i++) {
          pickedFiles.add(result.files[i]);
          selectedImages.add(File(result.files[i].path!));
          imageUrls.add(result.files[i].path!);
        }
      });
      
      if (result.files.length > (5 - pickedFiles.length + result.files.length)) {
        // AppSnackBar.show(
        //   message: "Only 5 images allowed. ${result.files.length - (5 - pickedFiles.length)} images were not added.",
        //   type: SnackType.warning,
        // );
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      if (selectedImages.length >= 5) {
        AppSnackBar.show(
          message: "Maximum 5 images allowed",
          type: SnackType.warning,
        );
        return;
      }

      // Calculate how many more images can be selected
      int remainingSlots = 5 - selectedImages.length;
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          isUploadingImage = true;
        });

        // Limit to remaining slots
        int imagesToAdd = images.length > remainingSlots ? remainingSlots : images.length;
        
        for (int i = 0; i < imagesToAdd; i++) {
          selectedImages.add(File(images[i].path));
          imageUrls.add(images[i].path);
        }

        await Future.delayed(const Duration(seconds: 1));
        setState(() => isUploadingImage = false);



        if (images.length > remainingSlots) {
          // AppSnackBar.show(
          //   message: "${images.length - remainingSlots} image(s) were not added (maximum 5 allowed)",
          //   type: SnackType.warning,
          // );
        }
      }
    } catch (e) {
      setState(() => isUploadingImage = false);
      // AppSnackBar.show(
      //   message: "Error selecting images: $e",
      //   type: SnackType.error,
      // );
    }
  }

  Future<void> takePhoto() async {
    try {
      if (selectedImages.length >= 5) {
        AppSnackBar.show(
          message: "Maximum 5 images allowed",
          type: SnackType.warning,
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImages.add(File(image.path));
          imageUrls.add(image.path);
          isUploadingImage = true;
        });

        await Future.delayed(const Duration(seconds: 1));
        setState(() => isUploadingImage = false);

        // AppSnackBar.show(
        //   message: "Photo taken successfully (${selectedImages.length}/5)",
        //   type: SnackType.success,
        // );
      }
    } catch (e) {
      setState(() => isUploadingImage = false);
      // AppSnackBar.show(
      //   message: "Error taking photo: $e",
      //   type: SnackType.error,
      // );
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
                  'Select Images (${selectedImages.length}/5)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Select 1-5 images for your offer\nYou can select multiple images at once',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
                        subtitle: 'Select 1-5 Images',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).pop();
                          pickImageFromGallery();
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
                          takePhoto();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.folder,
                        title: 'Files',
                        subtitle: 'Select 1-5 Images',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(context).pop();
                          pickFile();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (selectedImages.isNotEmpty)
                      Expanded(
                        child: _buildImageOption(
                          icon: Icons.delete_sweep,
                          title: 'Clear All',
                          subtitle: 'Remove All',
                          color: Colors.red,
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              selectedImages.clear();
                              imageUrls.clear();
                              pickedFiles.clear();
                            });
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
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    offerController.clearForm();
    productBrandController.clear();
    offerController.productBrandController.clear();
    setState(() {
      selectedImages.clear();
      imageUrls.clear();
      pickedFiles.clear();
      isUploadingImage = false;
    });
  }

  // Form validation method
  bool _isFormValid() {
    final productPrice = double.tryParse(offerController.productPriceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerController.offerPriceController.text) ?? 0.0;
    
    return offerController.selectedShopId.value.isNotEmpty &&
           offerController.selectedOfferType.value.isNotEmpty &&
           offerController.productNameController.text.isNotEmpty &&
           productBrandController.text.isNotEmpty &&
           offerController.productPriceController.text.isNotEmpty &&
           offerController.offerPriceController.text.isNotEmpty &&
           offerController.offerDescriptionController.text.isNotEmpty &&
           selectedImages.isNotEmpty && // Minimum 1 image required
           selectedImages.length >= 1 && // Explicit check for minimum 1 image
           offerPrice <= productPrice && // Offer price should not be greater than product price
           productPrice > 0 && // Product price should be greater than 0
           offerPrice > 0; // Offer price should be greater than 0
  }

  // Get validation message for button
  String _getValidationMessage() {
    if (selectedImages.isEmpty) {
      return "Select at least 1 image to enable";
    }
    
    if (offerController.selectedShopId.value.isEmpty) {
      return "Select a shop to enable";
    }
    
    if (offerController.selectedOfferType.value.isEmpty) {
      return "Select offer type to enable";
    }
    
    if (offerController.productNameController.text.isEmpty) {
      return "Enter product name to enable";
    }
    
    if (productBrandController.text.isEmpty) {
      return "Enter product brand to enable";
    }
    
    if (offerController.productPriceController.text.isEmpty) {
      return "Enter product price to enable";
    }
    
    if (offerController.offerPriceController.text.isEmpty) {
      return "Enter offer price to enable";
    }
    
    if (offerController.offerDescriptionController.text.isEmpty) {
      return "Enter offer description to enable";
    }
    
    final productPrice = double.tryParse(offerController.productPriceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerController.offerPriceController.text) ?? 0.0;
    
    if (productPrice <= 0) {
      return "Product price must be greater than 0";
    }
    
    if (offerPrice <= 0) {
      return "Offer price must be greater than 0";
    }
    
    if (offerPrice > productPrice) {
      return "Offer price cannot be greater than product price";
    }
    
    return "Create Offer";
  }

  final List<String> offerImages = [
    'assets/offerdesign1.png',
    'assets/offerdesign2.png',
    'assets/offerdesign3.png',
    'assets/offerdesign4.png',
  ];

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: offerImages.map((imgPath) {
                  final isSelected = offerController.selectedDesign.value == imgPath;
                  return GestureDetector(
                    onTap: () {
                      offerController.selectedDesign.value = imgPath;
                      setState(() {}); // Trigger rebuild for button validation
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imgPath,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Subscription Expired",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your subscription plan has expired. Please subscribe to continue posting ads.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/special-plans');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Subscribe Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
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

  void _showAdLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ad Limit Reached",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You've reached the ad limit for your current plan. Upgrade to continue posting ads.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/special-plans');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Upgrade Plan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
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
                      border: Border.all(
                        color: Color(0xFF00C853),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF00C853),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success Title
                  const Text(
                    'Offer Created Successfully!',
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
                    'Your Offer will be activated within 24 hours.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // OK Button
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 140, // Fixed smaller width
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Navigate back
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:   Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
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


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _clearForm();
        return true;
      },
      child: Scaffold(
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(0.0),

            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left :8.0),
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
                        "Add Offer",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10,),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Shop Dropdown
                     Obx(() => Stack(
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
                               offerController.isLoadingShops.value
                            ? 'Loading shops...'
                            : 'Select Shop',
                               style: TextStyle(
                                 color: Colors.grey,
                                 fontSize: 14,
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
                      items: offerController.shops.map((shop) {
                               return DropdownMenuItem<String>(
                          value: shop['id'].toString(),
                                 child: Text(
                                   shop['shop_name'] ?? 'Unknown Shop',
                                   style: const TextStyle(
                                     fontSize: 14,
                                     fontWeight: FontWeight.w500,
                                     color: Colors.grey,
                                   ),
                                 ),
                        );
                      }).toList(),
                             value: offerController.selectedShopId.value.isEmpty
                                 ? null
                                 : offerController.selectedShopId.value,
                             onChanged: (String? newValue) {
                               if (newValue != null) {
                                 offerController.selectedShopId.value = newValue;
                          final selectedShop = offerController.shops
                                     .firstWhere((shop) => shop['id'].toString() == newValue);
                          offerController.selectedShopName.value =
                              selectedShop['shop_name'] ?? 'Unknown Shop';
                          setState(() {}); // Trigger rebuild for button validation
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
                    )),
                    const SizedBox(height: 12),

                    // Offer Type Dropdown
                     Obx(() => Stack(
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
                               offerController.isLoadingOfferTypes.value
                                   ? 'Loading offer types...'
                                   : 'Select Offer Type',
                               style: TextStyle(
                                 color: Colors.grey,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                             iconStyleData: IconStyleData(
                               icon: offerController.isLoadingOfferTypes.value
                                   ? const SizedBox(
                                       width: 20,
                                       height: 20,
                                       child: CircularProgressIndicator(
                                         strokeWidth: 2,
                                         color: Colors.grey,
                                       ),
                                     )
                                   : const Icon(
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
                             items: offerController.offerTypes.isEmpty 
                                 ? [] 
                                 : offerController.offerTypes.map((Map<String, dynamic> offerType) {
                               return DropdownMenuItem<String>(
                        value: offerType['type_name'],
                                 child: Text(
                                   offerType['type_name'],
                                   style: const TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w500,
                                     color: Colors.grey,
                                   ),
                                 ),
                               );
                             }).toList(),
                             value: offerController.selectedOfferType.value.isEmpty
                                 ? null
                                 : offerController.selectedOfferType.value,
                             onChanged: (String? newValue) {
                               if (newValue != null) {
                                 offerController.selectedOfferType.value = newValue;
                                 setState(() {}); // Trigger rebuild for button validation
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
                    )),
                    const SizedBox(height: 16),

                    // Product & Offer Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  "Product Price",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: offerController.productPriceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // allow digits only
                                    LengthLimitingTextInputFormatter(7),    // max 7 digits
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Product Price',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  "Offer Price",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: offerController.offerPriceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(7),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Offer Price',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                      const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            const SizedBox(height: 25),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                '${offerController.calculateDiscount().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price validation warning
                    Builder(
                      builder: (context) {
                        final productPrice = double.tryParse(offerController.productPriceController.text) ?? 0.0;
                        final offerPrice = double.tryParse(offerController.offerPriceController.text) ?? 0.0;

                        if (productPrice > 0 && offerPrice > 0 && offerPrice > productPrice) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Offer price cannot be greater than product price",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),

                     // Product Name
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: offerController.productNameController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40),
                        ],
                        decoration: InputDecoration(
                          hintText: "Product Name",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Brand
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: productBrandController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30),
                        ],
                        decoration: InputDecoration(
                          hintText: "Product Brand",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),


                    // Design Preview
                    Obx(() => offerController.selectedDesign.value.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selected Design Preview:"),
                        const SizedBox(height: 10),
                        Image.asset(
                          offerController.selectedDesign.value,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ],
                    )
                        : const SizedBox.shrink()),
                    const SizedBox(height: 16),

                     // Upload Image Button
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
                       child: ElevatedButton(
                         onPressed: selectedImages.length >= 5 ? null : _showImagePicker,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: selectedImages.length >= 5 ?  Color(0xFF00C853) : Color(0xFF00C853),
                           foregroundColor: selectedImages.length >= 5 ? Colors.grey : Colors.black,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(10),
                           ),
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                         ),
                         child: Text(
                           selectedImages.isEmpty
                               ? "Select 1-5 Photos (0/5)"
                               : selectedImages.length >= 5
                                   ? "Maximum 5 photos selected"
                                   : "Add More Photos (${selectedImages.length}/5)",
                           style: const TextStyle(
                             fontSize: 16,
                             color: Colors.white,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(height: 16),

                     // Display selected images
                     if (selectedImages.isNotEmpty)
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
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Row(
                                 children: [
                                   Text(
                                     "Selected Images (${selectedImages.length}/5):",
                                     style: const TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: Colors.black87,
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   if (selectedImages.length < 1)
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                       decoration: BoxDecoration(
                                         color: Colors.red.withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(12),
                                         border: Border.all(color: Colors.red.withOpacity(0.3)),
                                       ),
                                       child: const Text(
                                         "Minimum 1 required",
                                         style: TextStyle(
                                           fontSize: 12,
                                           fontWeight: FontWeight.w500,
                                           color: Colors.red,
                                         ),
                                       ),
                                     ),
                                 ],
                               ),
                             ),
                             Container(
                               height: 120,
                               child: ListView.builder(
                                 scrollDirection: Axis.horizontal,
                                 itemCount: selectedImages.length,
                                 itemBuilder: (context, index) {
                                   return Container(
                                     margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                     child: Stack(
                                       children: [
                                         ClipRRect(
                                           borderRadius: BorderRadius.circular(8),
                                           child: Image.file(
                                             selectedImages[index],
                                             width: 100,
                                             height: 100,
                                             fit: BoxFit.cover,
                                           ),
                                         ),
                                         Positioned(
                                           top: 4,
                                           right: 4,
                                           child: GestureDetector(
                                             onTap: () {
                                               setState(() {
                                                 selectedImages.removeAt(index);
                                                 imageUrls.removeAt(index);
                                                 if (index < pickedFiles.length) {
                                                   pickedFiles.removeAt(index);
                                                 }
                                               });
                                             },
                                             child: Container(
                                               decoration: BoxDecoration(
                                                 color: Colors.red.withOpacity(0.8),
                                                 shape: BoxShape.circle,
                                               ),
                                               child: const Icon(
                                                 Icons.close,
                                                 color: Colors.white,
                                                 size: 20,
                                               ),
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   );
                                 },
                               ),
                             ),
                           ],
                         ),
                       ),
                    const SizedBox(height: 16),

                     // Offer Description
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
                       child: TextField(
                         controller: offerController.offerDescriptionController,
                         inputFormatters: [
                           LengthLimitingTextInputFormatter(200),
                         ],
                         maxLines: 3,
                         decoration: InputDecoration(
                           hintText: "Offer Description",
                           hintStyle: TextStyle(
                             color: Colors.grey,
                             fontSize: 14,
                             fontWeight: FontWeight.w500,
                           ),
                           contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                         onChanged: (_) => setState(() {}),
                       ),
                     ),
                    const SizedBox(height: 30),

                     // Create Offer Button
                     Container(
                       width: double.infinity,
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
                       child: Obx(() => ElevatedButton(
                         onPressed: (offerController.isCreatingOffer.value || !_isFormValid())
                             ? null
                             : () async {
                           // Set the product brand in the controller before making the API call
                           offerController.productBrandController.text = productBrandController.text;
                           bool success = await offerController.createOffer(imageFiles: selectedImages);
                           if (success) {
                             // Show success dialog
                             _showSuccessDialog();
                           } else if (offerController.isSubscriptionExpired.value) {
                             // Show subscription expired dialog
                             _showSubscriptionExpiredDialog();
                             // Reset the flag
                             offerController.resetSubscriptionExpiredFlag();
                           } else if (offerController.isAdLimitReached.value) {
                             // Show ad limit dialog
                             _showAdLimitDialog();
                             // Reset the flag
                             offerController.resetAdLimitFlag();
                           }
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: (offerController.isCreatingOffer.value || !_isFormValid())
                               ? Colors.grey
                               :  Color(0xFF00C853),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(10),
                           ),
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                         ),
                         child: offerController.isCreatingOffer.value
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
                                   "Creating Offer...",
                                   style: TextStyle(
                                     color: Colors.white,
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ],
                             )
                             : Text(
                                 _getValidationMessage(),
                                 style: TextStyle(
                                   color: _isFormValid() ? Colors.white : Colors.grey.shade600,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16,
                                 ),
                               ),
                       )),
                     ),
                    SizedBox(height: 50,)
                  ],
                ),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
