 import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import '../../../../Constants/app_colors.dart';

class CreateOffer extends StatefulWidget {
  const CreateOffer({super.key});

  @override
  State<CreateOffer> createState() => _CreateOfferState();
}

class _CreateOfferState extends State<CreateOffer> {
  final ImagePicker _picker = ImagePicker();
  List<File> selectedImages = [];
  bool isLoading = false;
  
  // Form controllers
  final TextEditingController offerTypeController = TextEditingController();
  final TextEditingController offerValueController = TextEditingController();
  final TextEditingController applicableProductsController = TextEditingController();
  final TextEditingController eligibilityCriteriaController = TextEditingController();
  final TextEditingController offerDescriptionController = TextEditingController();
  
  // Date controllers
  DateTime? startDate;
  DateTime? endDate;

  // Offer type options
  final List<String> offerTypes = [
    'Discount',
    'Buy One Get One',
    'Cashback',
    'Free Shipping',
    'Bundle Offer',
    'Seasonal Sale',
    'Clearance Sale',
    'Other'
  ];

  String? selectedOfferType;

  @override
  void dispose() {
    // Dispose all text controllers to prevent memory leaks
    offerTypeController.dispose();
    offerValueController.dispose();
    applicableProductsController.dispose();
    eligibilityCriteriaController.dispose();
    offerDescriptionController.dispose();
    super.dispose();
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
      if (fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47) {
        isValidSignature = true;
      }
      // JPEG signature: FF D8 FF
      else if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF) {
        isValidSignature = true;
      }
      // GIF signature: 47 49 46 38 (GIF8)
      else if (fileBytes[0] == 0x47 && fileBytes[1] == 0x49 && fileBytes[2] == 0x46 && fileBytes[3] == 0x38) {
        isValidSignature = true;
      }
      // WEBP signature: 52 49 46 46 (RIFF) followed by WEBP
      else if (fileBytes.length >= 12 && 
               fileBytes[0] == 0x52 && fileBytes[1] == 0x49 && fileBytes[2] == 0x46 && fileBytes[3] == 0x46 &&
               fileBytes[8] == 0x57 && fileBytes[9] == 0x45 && fileBytes[10] == 0x42 && fileBytes[11] == 0x50) {
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
        if (fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47) {
          extension = 'png';
        }
        // JPEG signature: FF D8 FF
        else if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF) {
          extension = 'jpg';
        }
        // GIF signature: 47 49 46 38 (GIF8)
        else if (fileBytes[0] == 0x47 && fileBytes[1] == 0x49 && fileBytes[2] == 0x46 && fileBytes[3] == 0x38) {
          extension = 'gif';
        }
        // WEBP signature: 52 49 46 46 (RIFF) followed by WEBP
        else if (fileBytes.length >= 12 && 
                 fileBytes[0] == 0x52 && fileBytes[1] == 0x49 && fileBytes[2] == 0x46 && fileBytes[3] == 0x46 &&
                 fileBytes[8] == 0x57 && fileBytes[9] == 0x45 && fileBytes[10] == 0x42 && fileBytes[11] == 0x50) {
          extension = 'webp';
        }
      }
      
      // Create a new file with proper extension
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String newFileName = 'offer_image_$timestamp.$extension';
      String tempDir = (await Directory.systemTemp).path;
      File newFile = File('$tempDir/$newFileName');
      
      // Write the bytes to the new file
      await newFile.writeAsBytes(fileBytes);
      
      print('Created properly named file: ${newFile.path} (extension: $extension)');
      return newFile;
    } catch (e) {
      print('Error creating properly named file: $e');
      return null;
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
          File? properlyNamedFile = await _createProperlyNamedFile(originalFile);
          
          if (properlyNamedFile != null) {
            if (mounted) {
              setState(() {
                if (selectedImages.length < 5) {
                  selectedImages.add(properlyNamedFile);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum 5 images allowed'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              });

              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Image selected successfully'),
              //     backgroundColor: Colors.green,
              //   ),
              // );
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
              content: Text('Image too large, please select an image smaller than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (!isValidType) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid image format. Please select PNG, JPEG, JPG, WEBP, or GIF'),
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
          File? properlyNamedFile = await _createProperlyNamedFile(originalFile);
          
          if (properlyNamedFile != null) {
            if (mounted) {
              setState(() {
                if (selectedImages.length < 5) {
                  selectedImages.add(properlyNamedFile);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maximum 5 images allowed'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != (isStartDate ? startDate : endDate)) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  bool _validateForm() {
    if (selectedOfferType == null) {
      _showError('Please select offer type');
      return false;
    }
    if (offerValueController.text.isEmpty) {
      _showError('Please enter offer value');
      return false;
    }
    if (applicableProductsController.text.isEmpty) {
      _showError('Please enter applicable products');
      return false;
    }
    if (startDate == null) {
      _showError('Please select start date');
      return false;
    }
    if (endDate == null) {
      _showError('Please select end date');
      return false;
    }
    if (eligibilityCriteriaController.text.isEmpty) {
      _showError('Please enter eligibility criteria');
      return false;
    }
    if (offerDescriptionController.text.isEmpty) {
      _showError('Please enter offer description');
      return false;
    }
    if (selectedImages.isEmpty) {
      _showError('Please upload at least one image');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createOffer() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement API call to create offer
      // This would be similar to the shop creation logic
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form and navigate back
      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      print("Error creating offer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    offerTypeController.clear();
    offerValueController.clear();
    applicableProductsController.clear();
    eligibilityCriteriaController.clear();
    offerDescriptionController.clear();
    setState(() {
      selectedOfferType = null;
      startDate = null;
      endDate = null;
      selectedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _clearForm();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _clearForm();
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Create Offer',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offer Type Dropdown
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
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
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
                        hint: Text(
                          'Select Offer Type',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        items: offerTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        value: selectedOfferType,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedOfferType = newValue;
                            offerTypeController.text = newValue ?? '';
                          });
                        },
                      ),
                    ),
                    if (selectedOfferType == null)
                      Positioned(
                        top: 2,
                        right: 15,
                        child: Text(
                          '*',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),

                // Offer Value
                customTextFieldWidget(
                  hintText: 'Offer Value',
                  controller: offerValueController,
                  isRequired: true,
                ),
                SizedBox(height: 20),

                // Applicable Products Dropdown
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
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
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
                        hint: Text(
                          'Select Applicable Products',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        items: ['All Products', 'Electronics', 'Clothing', 'Food & Beverages', 'Books', 'Other'].map((String product) {
                          return DropdownMenuItem<String>(
                            value: product,
                            child: Text(
                              product,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            applicableProductsController.text = newValue ?? '';
                          });
                        },
                      ),
                    ),
                    if (applicableProductsController.text.isEmpty)
                      Positioned(
                        top: 2,
                        right: 15,
                        child: Text(
                          '*',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),

                // Date Selection Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                startDate != null 
                                    ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                    : 'Start Date',
                                style: TextStyle(
                                  color: startDate != null ? Colors.black : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.calendar_month, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                endDate != null 
                                    ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                    : 'End Date',
                                style: TextStyle(
                                  color: endDate != null ? Colors.black : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.calendar_month, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Eligibility Criteria Dropdown
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
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
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
                        hint: Text(
                          'Select Eligibility Criteria',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        items: ['All Customers', 'New Customers', 'VIP Customers', 'Minimum Purchase', 'Other'].map((String criteria) {
                          return DropdownMenuItem<String>(
                            value: criteria,
                            child: Text(
                              criteria,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            eligibilityCriteriaController.text = newValue ?? '';
                          });
                        },
                      ),
                    ),
                    if (eligibilityCriteriaController.text.isEmpty)
                      Positioned(
                        top: 2,
                        right: 15,
                        child: Text(
                          '*',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),

                // Offer Description
                customTextFieldWidget(
                  hintText: 'Offer Description',
                  controller: offerDescriptionController,
                  isRequired: true,
                  maxLines: 3,
                ),
                SizedBox(height: 20),

                // Image Upload Section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, color: Colors.grey.shade600, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Offer Images (${selectedImages.length}/5)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Spacer(),
                            if (selectedImages.length < 5)
                              GestureDetector(
                                onTap: _showImagePicker,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add Image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Images Grid
                      Container(
                        padding: EdgeInsets.all(12),
                        child: selectedImages.isEmpty
                            ? Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade100,
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: InkWell(
                                  onTap: _showImagePicker,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 40,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Upload Images',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tap to select images (Max 5)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: selectedImages.length + (selectedImages.length < 5 ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == selectedImages.length && selectedImages.length < 5) {
                                    // Add new image button
                                    return InkWell(
                                      onTap: _showImagePicker,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey.shade100,
                                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 30,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Add More',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Image preview
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              selectedImages[index],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                          // Remove button
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
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
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Create Offer Button
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isLoading ? null : _createOffer,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: isLoading ? Colors.grey : AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: isLoading 
                                ? Row(
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
                                      Text('Creating Offer...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                                    ],
                                  )
                                : Text('Create Offer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
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
          height: maxLines > 1 ? null : 47,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update asterisk visibility
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
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
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
