import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../Routes/App_Pages.dart';
import '../Utils/SharedPrefUtils.dart';

class TicketController extends GetxController {
  // Form controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  
  // Selected values
  RxString selectedCategory = ''.obs;
  RxBool isCreatingTicket = false.obs;
  Rxn<PlatformFile> selectedFile = Rxn<PlatformFile>();

  // Categories - mapped to API expected values
  final List<String> categories = ['Login Issue', 'billing', 'Bug Report', 'Other'];

  @override
  void onInit() {
    super.onInit();
    _loadUserContactFromStorage();
  }

  Future<void> _loadUserContactFromStorage() async {
    await SharedPrefUtils.init();
    final String? storedEmail = SharedPrefUtils.getString('user_email');
    final String? storedPhone = SharedPrefUtils.getString('user_phone');

    if (storedEmail != null && storedEmail.isNotEmpty) {
      emailController.text = storedEmail;
    }
    if (storedPhone != null && storedPhone.isNotEmpty) {
      mobileNumberController.text = storedPhone;
    }
  }

  // Create ticket - returns created ticket data on success, null on failure
  Future<Map<String, dynamic>?> createTicket() async {
    try {
      isCreatingTicket.value = true;
      
      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        // AppSnackBar.show(
        //   message: "User not authenticated. Please login again.",
        //   type: SnackType.error,
        // );
        return null;
      }
      
      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        // AppSnackBar.show(
        //   message: "Invalid user ID. Please login again.",
        //   type: SnackType.error,
        // );
        return null;
      }

      // Validate required fields
      log("=== TICKET FORM VALIDATION ===");
      log("Email: '${emailController.text}'");
      log("Full Name: '${fullNameController.text}'");
      log("Mobile Number: '${mobileNumberController.text}'");
      log("Category: '${selectedCategory.value}'");
      log("Description: '${descriptionController.text}'");
      log("User ID: $userId");
      
      if (emailController.text.isEmpty) {
        log("❌ Validation failed: Email is empty");
        return null;
      }
      
      if (fullNameController.text.isEmpty) {
        log("❌ Validation failed: Full name is empty");
        return null;
      }
      
      if (mobileNumberController.text.isEmpty) {
        log("❌ Validation failed: Mobile number is empty");
        return null;
      }
      
      if (selectedCategory.value.isEmpty) {
        log("❌ Validation failed: No category selected");
        return null;
      }
      
      if (descriptionController.text.isEmpty) {
        log("❌ Validation failed: Description is empty");
        return null;
      }
      
      log("✅ All form validations passed");

      // Prepare request body
      Map<String, dynamic> requestBody = {
        "email": emailController.text.trim(),
        "full_name": fullNameController.text.trim(),
        "mobile_number": mobileNumberController.text.trim(),
        "category": selectedCategory.value,
        "description": descriptionController.text.trim(),
        "status": "pending",
        "user_id": userId,
        // For now we just send picked file name if available (adjust for real upload)
        "file_name": selectedFile.value?.name,
      };

      log("=== TICKET CREATION API CALL ===");
      log("User ID: $userId");
      log("API URL: ${AppRoutes.domainName}/api/ticket/create");
      log("Request Body: $requestBody");
      log("JSON String: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('${AppRoutes.domainName}/api/ticket/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      log("=== TICKET CREATION RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        Map<String, dynamic> ticketData = {
          "email": emailController.text.trim(),
          "full_name": fullNameController.text.trim(),
          "mobile_number": mobileNumberController.text.trim(),
          "category": selectedCategory.value,
          "description": descriptionController.text.trim(),
          "status": "pending",
          "file_name": selectedFile.value?.name,
        };

        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            // Merge any server-returned fields (like id/ticket_no)
            ticketData.addAll(parsed);
          }
          log("✅ Ticket created successfully!");
          log("Ticket Data: $ticketData");
        } catch (e) {
          log("⚠️ Could not parse response JSON: $e");
        }

        // Clear form after successful creation
        log("Clearing form after successful ticket creation");
        clearForm();
        return ticketData;
      } else {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          log("❌ Ticket creation failed!");
          log("Error Data: $data");
        } catch (e) {
          data = {"message": response.body};
          log("❌ Could not parse error response JSON: $e");
          log("Raw Error Response: ${response.body}");
        }

        // AppSnackBar.show(
        //   message: data['message'] ?? "Failed to create ticket. Please try again.",
        //   type: SnackType.error,
        // );
        return null;
      }
    } catch (e) {
      log("Error creating ticket: $e");
      // AppSnackBar.show(
      //   message: "Error creating ticket: $e",
      //   type: SnackType.error,
      // );
      return null;
    } finally {
      isCreatingTicket.value = false;
    }
  }

  // Clear form
  void clearForm() {
    emailController.clear();
    fullNameController.clear();
    mobileNumberController.clear();
    descriptionController.clear();
    selectedCategory.value = '';
    selectedFile.value = null;
  }

  // Set category
  void setCategory(String category) {
    selectedCategory.value = category;
    log("=== CATEGORY SELECTION ===");
    log("Selected Category: $category");
  }
}
