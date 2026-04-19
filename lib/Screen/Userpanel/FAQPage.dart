
import 'package:flutter/material.dart';

import '../../Constants/GlobalVariables.dart';
import '../../Constants/app_colors.dart';
import '../AdminPanel/AdminDashboard/HomePage.dart';
import '../DrawerScreen.dart';
import 'Customappbar.dart';
import 'UserDashboard/UserHome.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<String> faqs = [
    'What photos are not allowed in my profile?',
    'How do I change my password?',
    'How can I delete my account?',
    'Why was my photo rejected?',
    'How do I contact support?',
  ];

  final List<String> answers = [
    'Avoid blurry, inappropriate, or misleading photos.',
    'Go to settings and select "Change Password".',
    'Visit account settings and choose "Delete Account".',
    'Your photo might have violated community standards.',
    'You can reach us through the Help section in settings.',
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.white,
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(),
        body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  "FAQ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            ...List.generate(faqs.length, (index) {
              return Column(
                children: [
                  faqContainerBox(
                    question: faqs[index],
                    index: index,
                  ),
                  if (_expandedIndex == index)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        answers[index],
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      ),
      ),
    );
  }

  Widget faqContainerBox({
    required String question,
    required int index,
  }) {
    final isExpanded = _expandedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all( color: Color(0xFF00C853), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                isExpanded ? Icons.remove : Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
