
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../../../Utils/ApiService.dart';
import '../../../Utils/SharedPrefUtils.dart';
import '../../DrawerScreen.dart';
import '../Customappbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  String errorMessage = '';
  static const Color redColor = Color(0xFFEA0212);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // Fetch user data from API
      final response = await ApiService.get('/api/user/users/$userIdStr');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load profile data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchUserData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (userData != null)
              Column(
                children: [
                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: redColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Username
                        Text(
                          userData!['username'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Role Badge
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        //   decoration: BoxDecoration(
                        //     color: Color(0xFF00C853),
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     userData!['role'] == 'shopkeeper'
                        //         ? 'Shop Owner'
                        //         : (userData!['role'] ?? 'N/A'),
                        //     style: const TextStyle(
                        //       color: Colors.white,
                        //       fontSize: 12,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // User ID
                        // _buildInfoRow(
                        //   icon: Icons.badge,
                        //   label: 'User ID',
                        //   value: userData!['id']?.toString() ?? 'N/A',
                        // ),

                        
                        // Email
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: userData!['email'] ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: userData!['phone'] ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        
                        // Role
                        // _buildInfoRow(
                        //   icon: Icons.person_pin,
                        //   label: 'Role',
                        //   value:
                        //     userData!['role'] == 'shopkeeper'
                        //         ? 'Shop Owner'
                        //         : (userData!['role'] ?? 'N/A'),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 48,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       // Navigate to edit profile page
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => const EditProfilePage(),
                  //         ),
                  //       );
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: redColor,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //     ),
                  //     child: const Text(
                  //       'Edit Profile',
                  //       style: TextStyle(
                  //         fontFamily: 'Poppins',
                  //         fontWeight: FontWeight.w700,
                  //         fontSize: 16,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Color(0xFF00C853),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Placeholder for EditProfilePage - you can implement this later
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: const Center(
        child: Text('Edit Profile Page - To be implemented'),
      ),
    );
  }
}
