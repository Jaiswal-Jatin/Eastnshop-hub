import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../Routes/App_Pages.dart';
import '../../../Utils/SharedPrefUtils.dart';
import '../../DrawerScreen.dart';
import '../Customappbar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController feedbackController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendFeedback() async {
    final text = feedbackController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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

      // Prepare request body
      Map<String, dynamic> requestBody = {
        "user_id": userId,
        "message": text,
      };

      log("=== FEEDBACK SUBMISSION API CALL ===");
      log("User ID: $userId");
      log("API URL: ${AppRoutes.domainName}/api/feedback/create");
      log("Request Body: $requestBody");
      log("JSON String: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('${AppRoutes.domainName}/api/feedback/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      log("=== FEEDBACK SUBMISSION RESPONSE ===");
      log("Status Code: ${response.statusCode}");
      log("Response Headers: ${response.headers}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          log("✅ Feedback submitted successfully!");
          log("Response Data: $data");
        } catch (e) {
          data = {"message": response.body};
          log("⚠️ Could not parse response JSON: $e");
          log("Raw Response: ${response.body}");
        }


        // Clear form after successful submission
        feedbackController.clear();

        // Show Thank You dialog and navigate back on OK
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Thank You'),
                content: const Text('Your feedback has been submitted successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close dialog
                      Navigator.of(context).maybePop(); // go back
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          log("❌ Feedback submission failed!");
          log("Error Data: $data");
        } catch (e) {
          data = {"message": response.body};
          log("❌ Could not parse error response JSON: $e");
          log("Raw Error Response: ${response.body}");
        }

        // AppSnackBar.show(
        //   message: data['message'] ?? "Failed to submit feedback. Please try again.",
        //   type: SnackType.error,
        // );
      }
    } catch (e) {
      log("❌ Exception during feedback submission: $e");
      // AppSnackBar.show(
      //   message: "Network error. Please check your connection and try again.",
      //   type: SnackType.error,
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const redColor = Color(0xFFEA0212);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: const BackButton(color: Colors.black),
      //   centerTitle: true,
      //   title: const Text(
      //     'Feedback',
      //     style: TextStyle(
      //       fontFamily: 'Poppins',
      //       fontWeight: FontWeight.w700,
      //       fontSize: 18,
      //       color: Colors.black,
      //     ),
      //   ),
      // ),
     appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(), // Your drawer widget
      body: Column(
        children: [
      
             Padding(
          padding: const EdgeInsets.only(left :8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      const SizedBox(width: 8),
      const Text(
        "Feedback",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
            ],
          ),
        ),
   SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
                        /// Feedback input
              TextField(
                controller: feedbackController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Write your feedback here',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
        
              /// Send Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey :  Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Feedback',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              )
          
          ],
        ),
      )
        ],
      ),
    );
  }
}
