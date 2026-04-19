import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../Models/TicketModel.dart';
import '../Routes/App_Pages.dart';
import '../Utils/SharedPrefUtils.dart';

class TicketListController extends GetxController {
  // Observable variables
  RxList<TicketModel> tickets = <TicketModel>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
  }

  // Fetch tickets for the logged-in user
  Future<void> fetchTickets() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        // AppSnackBar.show(
        //   message: "User not authenticated. Please login again.",
        //   type: SnackType.error,
        // );
        return;
      }
      
      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        // AppSnackBar.show(
        //   message: "Invalid user ID. Please login again.",
        //   type: SnackType.error,
        // );
        return;
      }

      log("=== FETCH TICKETS API CALL ===");
      log("User ID: $userId");
      log("API URL: ${AppRoutes.domainName}/api/ticket/user/$userId");

      final response = await http.get(
        Uri.parse('${AppRoutes.domainName}/api/ticket/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      log("=== FETCH TICKETS RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          dynamic data = jsonDecode(response.body);
          List<TicketModel> ticketList = [];
          
          // Handle different response formats
          if (data is List) {
            // Direct array of tickets
            ticketList = data.map((ticket) => TicketModel.fromJson(ticket)).toList();
          } else if (data is Map && data['data'] != null) {
            // Response with data wrapper
            List<dynamic> ticketsData = data['data'];
            ticketList = ticketsData.map((ticket) => TicketModel.fromJson(ticket)).toList();
          } else if (data is Map && data['tickets'] != null) {
            // Response with tickets wrapper
            List<dynamic> ticketsData = data['tickets'];
            ticketList = ticketsData.map((ticket) => TicketModel.fromJson(ticket)).toList();
          }
          
          tickets.value = ticketList;
          log("✅ Successfully fetched ${ticketList.length} tickets");
          
        } catch (e) {
          log("❌ Error parsing tickets response: $e");
          errorMessage.value = "Error parsing tickets data";
          // AppSnackBar.show(
          //   message: "Error loading tickets. Please try again.",
          //   type: SnackType.error,
          // );
        }
      } else {
        try {
          dynamic errorData = jsonDecode(response.body);
          String errorMsg = errorData['message'] ?? "Failed to fetch tickets";
          errorMessage.value = errorMsg;
          log("❌ API Error: $errorMsg");
          // AppSnackBar.show(
          //   message: errorMsg,
          //   type: SnackType.error,
          // );
        } catch (e) {
          errorMessage.value = "Failed to fetch tickets";
          log("❌ Error parsing error response: $e");
          // AppSnackBar.show(
          //   message: "Failed to fetch tickets. Please try again.",
          //   type: SnackType.error,
          // );
        }
      }
    } catch (e) {
      log("Error fetching tickets: $e");
      errorMessage.value = "Network error occurred";
      // AppSnackBar.show(
      //   message: "Network error. Please check your connection.",
      //   type: SnackType.error,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh tickets
  Future<void> refreshTickets() async {
    await fetchTickets();
  }

  // Get tickets by status
  List<TicketModel> getTicketsByStatus(String status) {
    return tickets.where((ticket) => ticket.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Get ticket count by status
  int getTicketCountByStatus(String status) {
    return tickets.where((ticket) => ticket.status.toLowerCase() == status.toLowerCase()).length;
  }
}
