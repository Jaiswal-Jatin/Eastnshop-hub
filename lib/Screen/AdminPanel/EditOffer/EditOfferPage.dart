
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../Constants/app_colors.dart';
import '../../../Controllers/ActiveOffersController.dart';
import '../../../Controllers/offerController.dart';
import '../../../Utils/SharedPrefUtils.dart';
import '../../DrawerScreen.dart';
import '../../Userpanel/Customappbar.dart';

class EditOfferPage extends StatefulWidget {
  final Map<String, dynamic> offer;

  const EditOfferPage({super.key, required this.offer});

  @override
  State<EditOfferPage> createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  final ActiveOffersController controller = Get.find<ActiveOffersController>();
  final OfferController offerController = Get.put(OfferController());
  final ImagePicker _picker = ImagePicker();
  
  // Image handling
  List<PlatformFile> pickedFiles = [];
  List<File> selectedImages = [];
  List<String> imageUrls = [];
  bool isUploadingImage = false;

  // Text controllers
  late TextEditingController productNameController;
  late TextEditingController productBrandController;
  late TextEditingController productPriceController;
  late TextEditingController offerPriceController;
  late TextEditingController offerDescriptionController;
  late TextEditingController photoUrlController;

  // Form state
  String selectedOfferType = 'Discount';
  String selectedOfferDesign = 'simple';
  String? selectedShopId;
  String? selectedShopName;
  bool isLoading = false;

  // Offer types will be fetched from API via OfferController

  // Sample images
  final List<String> offerImages = [
    'assets/offerdesign1.png',
    'assets/offerdesign2.png',
    'assets/offerdesign3.png',
    'assets/offerdesign4.png',
  ];

  // Mapping between database values and asset paths
  final Map<String, String> designMapping = {
    'simple': 'assets/offerdesign1.png',
    'banner-v1': 'assets/offerdesign1.png',
    'banner-v2': 'assets/offerdesign2.png',
    'banner-v3': 'assets/offerdesign3.png',
    'banner-v4': 'assets/offerdesign4.png',
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    productNameController =
        TextEditingController(text: widget.offer['product_name']?.toString() ?? '');
    productBrandController =
        TextEditingController(text: widget.offer['product_brand']?.toString() ?? '');
    productPriceController =
        TextEditingController(text: widget.offer['product_price']?.toString() ?? '');
    offerPriceController =
        TextEditingController(text: widget.offer['offer_price']?.toString() ?? '');
    offerDescriptionController =
        TextEditingController(text: widget.offer['offer_description']?.toString() ?? '');
    photoUrlController =
        TextEditingController(text: widget.offer['photo_url']?.toString() ?? '');

    print("=== FORM INITIALIZATION ===");
    print("🔍 Product Brand from offer data: '${widget.offer['product_brand']}'");
    print("🔍 Product Brand controller text: '${productBrandController.text}'");

    // Normalize offer type - handle case sensitivity
    String dbOfferType = widget.offer['offer_type']?.toString() ?? 'General';
    print("=== OFFER TYPE INITIALIZATION ===");
    print("DB Offer Type: '$dbOfferType'");
    
    // Find matching offer type from API data (case-insensitive)
    String? matchedOfferType;
    for (Map<String, dynamic> offerTypeData in offerController.offerTypes) {
      String typeName = offerTypeData['type_name']?.toString() ?? '';
      if (typeName.toLowerCase() == dbOfferType.toLowerCase()) {
        matchedOfferType = typeName;
        break;
      }
    }
    
    if (matchedOfferType != null) {
      selectedOfferType = matchedOfferType;
      print("✅ Matched offer type: '$matchedOfferType'");
    } else {
      // If no match found, use the first available type or default
      if (offerController.offerTypes.isNotEmpty) {
        selectedOfferType = offerController.offerTypes.first['type_name']?.toString() ?? 'General';
        print("⚠️ No match found, using first available: '$selectedOfferType'");
      } else {
        selectedOfferType = 'General';
        print("⚠️ No offer types available, defaulting to 'General'");
      }
    }
    
    print("Final selected offer type: '$selectedOfferType'");

    // Map design
    String dbDesignValue = widget.offer['offer_design']?.toString() ?? 'simple';
    selectedOfferDesign =
        designMapping[dbDesignValue] ?? 'assets/offerdesign1.png';

    selectedShopId = widget.offer['shop_id']?.toString();
    selectedShopName = widget.offer['shop_name']?.toString();
  }

  // Normalize offer type for API consistency
  String _normalizeOfferTypeForAPI(String offerType) {
    // Map frontend values to API-expected values
    switch (offerType.toLowerCase()) {
      case 'new year':
        return 'New year'; // API expects this format
      case 'big dhamaka':
        return 'Big Dhamaka'; // API expects this format
      case 'general':
        return 'General';
      case 'festival':
        return 'Festival';
      case 'bumper':
        return 'Bumper';
      default:
        return 'General'; // Default fallback
    }
  }

  @override
  void dispose() {
    productNameController.dispose();
    productBrandController.dispose();
    productPriceController.dispose();
    offerPriceController.dispose();
    offerDescriptionController.dispose();
    photoUrlController.dispose();
    // Clear image state
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
        // AppSnackBar.show(
        //   message: "Maximum 5 images allowed",
        //   type: SnackType.warning,
        // );
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
        // AppSnackBar.show(
        //   message: "Maximum 5 images allowed",
        //   type: SnackType.warning,
        // );
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

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: designMapping.entries.map((entry) {
                  final dbValue = entry.key;
                  final assetPath = entry.value;
                  final isSelected = selectedOfferDesign == assetPath;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedOfferDesign = assetPath;
                      });
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
                        child: Column(
                          children: [
                            Image.asset(
                              assetPath,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                dbValue,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
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

  double calculateDiscount() {
    final productPrice =
        double.tryParse(productPriceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerPriceController.text) ?? 0.0;

    if (productPrice <= 0) return 0.0;

    return ((productPrice - offerPrice) / productPrice) * 100;
  }

  // Form validation method
  bool _isFormValid() {
    final productPrice = double.tryParse(productPriceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerPriceController.text) ?? 0.0;
    
    return selectedShopId != null &&
           selectedShopId!.isNotEmpty &&
           productNameController.text.trim().isNotEmpty &&
           productBrandController.text.trim().isNotEmpty &&
           productPriceController.text.trim().isNotEmpty &&
           offerPriceController.text.trim().isNotEmpty &&
           offerDescriptionController.text.trim().isNotEmpty &&
           offerPrice <= productPrice && // Offer price should not be greater than product price
           productPrice > 0 && // Product price should be greater than 0
           offerPrice > 0 && // Offer price should be greater than 0
           productNameController.text.trim().length >= 3 ;  // Product name should be at least 3 characters

  }

  // Get validation message for button
  String _getValidationMessage() {
    if (selectedShopId == null || selectedShopId!.isEmpty) {
      return "Select a shop to enable";
    }
    
    if (productNameController.text.trim().isEmpty) {
      return "Enter product name to enable";
    }
    
    if (productNameController.text.trim().length < 3) {
      return "Product name must be at least 3 characters";
    }
    
    if (productBrandController.text.trim().isEmpty) {
      return "Enter product brand to enable";
    }
    
    if (productPriceController.text.trim().isEmpty) {
      return "Enter product price to enable";
    }
    
 
    
    final productPrice = double.tryParse(productPriceController.text) ?? 0.0;
    final offerPrice = double.tryParse(offerPriceController.text) ?? 0.0;
    
    if (productPrice <= 0) {
      return "Product price must be greater than 0";
    }
    
    if (offerPrice <= 0) {
      return "Offer price must be greater than 0";
    }
    
    if (offerPrice > productPrice) {
      return "Offer price cannot be greater than product price";
    }
    
    return "Update Offer";
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
                        color: Colors.green,
                        width: 3,
                      ),
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
                    'Offer Updated Successfully!',
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
                    'Your offer has been updated successfully. It will be visible to customers now.',
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
                        Navigator.of(context).pop(); // Navigate back to home screen
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

  Future<void> _updateOffer() async {
    if (selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      int userId = int.tryParse(userIdStr ?? '') ?? 0;

      String dbDesignValue = 'simple';
      for (var entry in designMapping.entries) {
        if (entry.value == selectedOfferDesign) {
          dbDesignValue = entry.key;
          break;
        }
      }

      // Normalize offer type for API consistency
      String normalizedOfferType = _normalizeOfferTypeForAPI(selectedOfferType);
      
      Map<String, dynamic> offerData = {
        "id": widget.offer['id'],
        "user_id": userId,
        "shop_id": int.tryParse(selectedShopId!) ?? 0,
        "offer_type": normalizedOfferType,
        "product_price": double.tryParse(productPriceController.text) ?? 0.0,
        "offer_price": double.tryParse(offerPriceController.text) ?? 0.0,
        "product_name": productNameController.text,
        "product_brand": productBrandController.text,
        "offer_design": dbDesignValue,
        "offer_description": offerDescriptionController.text,
        "photo_url": photoUrlController.text,
      };

      print("=== UPDATE OFFER ===");
      print("Offer data: $offerData");
      print("Selected images count: ${selectedImages.length}");
      print("🔍 Product Brand from controller: '${productBrandController.text}'");
      print("🔍 Product Brand length: ${productBrandController.text.length}");

      // Support image uploads for editing offers
      bool success = await controller.editOffer(offerData, imageFiles: selectedImages.isNotEmpty ? selectedImages : null);

      if (success) {
        // Show success dialog
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update offer')),
        );
      }
    } catch (e) {
      print("Error updating offer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    );
    
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    );
    
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    );


    return Scaffold(
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),



      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () =>  Navigator.pop(context),
                          child: Icon(Icons.arrow_back)),


                      const SizedBox(width: 8),
                      const Text(
                        "Edit Offer",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  

                  
                  // Dropdown: Select Shop
                  Obx(() => Container(
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
                      style: TextStyle(color: Colors.grey),
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
                        fillColor: Colors.white, // input background white
                      ),
                      hint: Text(
                        controller.isLoadingShops.value
                            ? 'Loading shops...'
                            : 'Select Shop',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      iconStyleData: IconStyleData(
                        icon: controller.isLoadingShops.value
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
                      value: selectedShopId,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedShopId = newValue;
                            final selectedShop = controller.shops.firstWhere(
                                    (shop) => shop['id'].toString() == newValue);
                            selectedShopName = selectedShop['shop_name'] ?? 'Unknown Shop';
                          });
                        }
                      },
                      onMenuStateChange: (isOpen) {
                        if (isOpen) {
                          HapticFeedback.lightImpact();
                        }
                      },
                    ),
                  )),
                  const SizedBox(height: 12),

                  // Dropdown: Offer Type
                  Obx(() => Container(
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
                      style: TextStyle(color: Colors.grey),
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
                        fillColor: Colors.white, // input background white
                      ),
                      hint: Text(
                        offerController.isLoadingOfferTypes.value
                            ? 'Loading offer types...'
                            : 'Offer Type',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
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
                      value: selectedOfferType,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedOfferType = newValue;
                          });
                        }
                      },
                      onMenuStateChange: (isOpen) {
                        if (isOpen) {
                          HapticFeedback.lightImpact();
                        }
                      },
                    ),
                  )),
                  const SizedBox(height: 16),


                  // Price Inputs + Discount
                  SizedBox(
                    height: 80, // increased height to fit labels
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Price
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Product Price",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: productPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),

                                    LengthLimitingTextInputFormatter(6),

                                ],
                                style: const TextStyle(color: Colors.grey),
                                decoration: InputDecoration(
                                  hintText: 'Enter Price',
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
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
                                onChanged: (_) {
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Offer Price
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Offer Price",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: offerPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),

                                    LengthLimitingTextInputFormatter(6),

                                ],
                                style: const TextStyle(color: Colors.grey),
                                decoration: InputDecoration(
                                  hintText: 'Enter Offer',
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
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
                                onChanged: (_) {
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Discount %
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 22, right: 10), // align with fields
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${calculateDiscount().toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price validation warning
                  Builder(
                    builder: (context) {
                      final productPrice = double.tryParse(productPriceController.text) ?? 0.0;
                      final offerPrice = double.tryParse(offerPriceController.text) ?? 0.0;

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
                  

                  TextField(
                    controller: productNameController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(40),
                    ],
                    maxLength: 100,
                    style: const TextStyle(color: Colors.grey),
                    decoration: InputDecoration(
                      hintText: "Product Name",
                      border: border,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: const TextStyle(color: Colors.grey),
                      counterText: '', // Hide character counter
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Brand Field
                  TextField(
                    controller: productBrandController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                    ],
                    maxLength: 50,
                    style: const TextStyle(color: Colors.grey),
                    decoration: InputDecoration(
                      hintText: "Product Brand",
                      border: border,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: const TextStyle(color: Colors.grey),
                      counterText: '', // Hide character counter
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Current Images Display
                  if (widget.offer['photo_url'] != null && widget.offer['photo_url'].isNotEmpty)
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
                                Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Current Offer Images:",
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
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.offer['images']?.length ?? 0,
                              itemBuilder: (context, index) {
                                String imageUrl = widget.offer['images'][index];
                                return Container(
                                  margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(imageUrl,
width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Image Upload Section
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

                        
                        // Image selection button
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.blue.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedImages.isEmpty 
                                              ? "Add Images to Update Offer"
                                              : "Update Images (${selectedImages.length} selected)",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Tap to select 1-5 images for your offer",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.blue.shade600,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Selected images preview
                        if (selectedImages.isNotEmpty)
                          Container(
                            height: 120,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8, bottom: 8),
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
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
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


                  TextField(
                    controller: offerDescriptionController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                    maxLines: 3,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.grey),
                    decoration: InputDecoration(
                      hintText: "Offer Description",
                      border: border,
                      enabledBorder: enabledBorder,
                      focusedBorder: focusedBorder,
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: const TextStyle(color: Colors.grey),
                      counterText: '', // Hide character counter
                    ),
                  ),
                  const SizedBox(height: 50),

                  ElevatedButton(
                    onPressed: (isLoading || !_isFormValid()) ? null : _updateOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isLoading || !_isFormValid())
                          ? Colors.grey
                          :
                      Color(0xFF00C853),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: isLoading
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
                        Text("Updating Offer...",
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
                        : Text(
                            _getValidationMessage(),
                            style: TextStyle(
                              color: _isFormValid() ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                  ),
                  SizedBox(height: 60,)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
