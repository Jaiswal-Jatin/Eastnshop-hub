
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../Constants/GlobalVariables.dart';
import '../../../Utils/ApiService.dart';
import '../../../Utils/SharedPrefUtils.dart';
import '../../../Utils/TokenManager.dart';
import '../../AdminPanel/AdminDashboard/HomePage.dart';
import '../../DrawerScreen.dart';
import '../../Login/Login.dart';
import '../Customappbar.dart';
import '../UserDashboard/UserHome.dart';
import 'ChangeMobile.dart';
import 'ChangePaswword.dart';
import 'Feedback.dart';
import 'ProfilePage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeletingAccount = false;

  @override
  void dispose() {
    updateGlobalSettings("false");
    super.dispose();
  }

  /// Show confirmation dialog for account deletion
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete account API call
  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        _showErrorSnackBar('Unable to retrieve user information');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      // First, fetch current user data to get the correct phone number
      final userResponse = await ApiService.get('/api/user/users/$userIdStr');
      
      if (userResponse.statusCode != 200) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('Unable to fetch user information');
        return;
      }

      final userData = jsonDecode(userResponse.body);
      String? userMobile = userData['phone'];
      
      if (userMobile == null || userMobile.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('Unable to retrieve user phone number');
        return;
      }

      // Make API call to delete account using DELETE method
      final response = await ApiService.delete(
        '/api/user/delete-account',
        body: {
          "mobile": userMobile,
        },
        includeAuth: true,
      );
      
      // Debug logging
      print('Delete account API call made');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Close loading dialog
      Navigator.of(context).pop();

      // Check for success - be more flexible with status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Account deleted successfully
        _showSuccessDialog();
      } else {
        // Handle error response
        String errorMessage = 'Failed to delete account. Please try again.';
        try {
          final responseData = response.body;
          if (responseData.isNotEmpty) {
            // Try to parse JSON response for error message
            try {
              final errorJson = jsonDecode(responseData);
              if (errorJson['message'] != null) {
                errorMessage = errorJson['message'];
                // Check if it's actually a success message despite the status code
                if (errorJson['message'].toString().toLowerCase().contains('success')) {
                  _showSuccessDialog();
                  return;
                }
              }
            } catch (e) {
              // If not JSON, use the raw response
              errorMessage = responseData;
            }
          }
        } catch (e) {
          // Use default error message
        }
        
        // Log the response for debugging
        print('Delete account response: ${response.statusCode} - ${response.body}');
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar('Network error. Please check your connection and try again.');
    } finally {
      setState(() {
        _isDeletingAccount = false;
      });
    }
  }

  /// Show success dialog and navigate to login
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Account Deleted',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: const Text(
            'Your account has been successfully deleted. You will be redirected to the login page.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to login page and clear all data
  Future<void> _navigateToLogin() async {
    try {
      // Clear all authentication data
      await TokenManager.clearTokens();
      await SharedPrefUtils.init();
      await SharedPrefUtils.clearAll(); // Clear all stored data
      
      // Navigate to login page and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Even if clearing data fails, navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = 48.0;

    return WillPopScope(
      onWillPop: () async {
        // Navigate directly to home page instead of following history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
          ),
          (route) => false, // Remove all previous routes
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), 
        appBar: getGlobalSettings() == "true" ? const CustomAppBarWithDrawer() : null,
        drawer: const DrawerScreen(), 
        body: Column(
        children: [ 
            Padding(
              padding: const EdgeInsets.only(left :10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      // Navigate directly to home page instead of following history
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ), 
            SizedBox(height: 16,),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
              /// My Profile
              _SettingsButton(
                label: 'My Profile',

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              /// Change Mobile Number
              _SettingsButton(
                label: 'Change Mobile  Number',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangeMobileScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              /// Change Password
              _SettingsButton(
                label: 'Change Password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              /// Feedback
              _SettingsButton(
                label: 'Feedback',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              /// Delete Account
              _SettingsButton(
                label: _isDeletingAccount ? 'Deleting Account...' : 'Delete Account',
                borderColor: Colors.red,
                textColor: Colors.red,
                onTap: _isDeletingAccount ? null : () {
                  _showDeleteAccountDialog(context);
                },
              ),

                      
                ],
              ),
            )
              ],
      ),
      ),
    );
  }
}

/// Reusable Button Widget
class _SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color textColor;

  const _SettingsButton({
    required this.label,
    required this.onTap,
    this.borderColor = const Color(0xFF2C3E50), // Dark grey
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDisabled ? Colors.grey : borderColor,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDisabled ? Colors.grey : textColor,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 16, 
              color: isDisabled ? Colors.grey : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

