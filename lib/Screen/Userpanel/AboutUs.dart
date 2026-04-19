import 'package:flutter/material.dart';

import '../../Constants/GlobalVariables.dart';
import '../../Constants/app_colors.dart';
import '../AdminPanel/AdminDashboard/HomePage.dart';
import '../DrawerScreen.dart';
import 'Customappbar.dart';
import 'UserDashboard/UserHome.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate directly to home page instead of following history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                globalUser.value == true ? HomePage() : HomePage(),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => globalUser.value == true
                                ? HomePage()
                                : HomePage(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "About Us",
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
                  _heroSection(),
                  const SizedBox(height: 20),
                  _contentSection(),
                  const SizedBox(height: 20),
                  // _middleSection(context),
                  // const SizedBox(height: 20),
                  // _footerSection(),
                ],
              ),
              SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }

  // Hero section with title
  Widget _heroSection() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome to Eastnshoptech!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Discover amazing deals and exclusive offers near you.',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    ),
  );

  // Main content section
  Widget _contentSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        _cardSection(
          title: 'About Us',
          content: [
            """We believe that customers are always looking for better deals and valuable offers. That’s why we set out to simplify the way people discover discounts and savings opportunities around them.
Our platform is designed to connect customers with the best deals available in their local area, making it easier than ever to save both time and money. Whether it’s everyday essentials or special experiences, we aim to bring the most relevant offers closer to you.
At the same time, we empower businesses to reach nearby customers more effectively. Our dedicated team works closely with partners to help promote their deals, increase visibility, and drive meaningful engagement.
""",
          ],
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 20),
        _cardSection(
          title: 'Our Mission',
          content: [
            """Together, we create a smarter, more convenient way for customers and businesses to connect through great offers.
To be your go-to parnter in promotion. We are dedicated to helping you stretch reach to customers and make attractive deals to attract them.""",
          ],
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 20),
        // _gradientButton(
        //   text: 'Explore More',
        //   gradientColors: [AppColors.primaryRed, Colors.redAccent.shade200],
        //   onTap: () {},
        // ),
      ],
    ),
  );

  // Card style section
  Widget _cardSection({
    required String title,
    required List<String> content,
    required IconData icon,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryRed),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...content.map(
          (line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    ),
  );

  // Middle section with image
  // Widget _middleSection(BuildContext context) => Container(
  //   width: double.infinity,
  //   color: Colors.grey.shade100,
  //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
  //   child: Column(
  //     children: [
  //       Image.asset('assets/logo_chill_offer.png', height: 70, width: 70),
  //       const SizedBox(height: 15),
  //       ..._loremText()
  //           .map((line) => Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 2),
  //         child: Text(
  //           line,
  //           textAlign: TextAlign.center,
  //           style: const TextStyle(fontSize: 14),
  //         ),
  //       ))
  //           .toList(),
  //       const SizedBox(height: 20),
  //       _gradientButton(
  //         text: 'Join Chill Offer Today',
  //         gradientColors: [AppColors.primaryRed, Colors.redAccent.shade200],
  //         onTap: () {},
  //       ),
  //     ],
  //   ),
  // );
  //
  // // Footer section
  // Widget _footerSection() => Container(
  //   width: double.infinity,
  //   color: Colors.black,
  //   padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
  //   child: Column(
  //     children: [
  //       const Text(
  //         'Follow Us',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Image.asset('assets/Icon.png', height: 24, width: 24),
  //           const SizedBox(width: 12),
  //           const Text('f', style: TextStyle(color: Colors.white, fontSize: 20)),
  //           const SizedBox(width: 12),
  //           const Text('G', style: TextStyle(color: Colors.white, fontSize: 20)),
  //         ],
  //       ),
  //       const Divider(color: Colors.grey, height: 30),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: const [
  //           Text('Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 15)),
  //           Text('Terms & Conditions', style: TextStyle(color: Colors.white, fontSize: 15)),
  //         ],
  //       ),
  //     ],
  //   ),
  // );

  // Gradient button widget
  Widget _gradientButton({
    required String text,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );

  // Sample text
  // List<String> _loremText() => [
  //   "Lorem Ipsum is simply dummy text of the printing and",
  //   "typesetting industry. Lorem Ipsum has been the",
  //   "industry's standard dummy text ever since the 1500s,",
  //   "when an unknown printer took a galley of type and",
  //   "scrambled it to make a type specimen book. Lorem",
  //   "Ipsum is simply dummy text of the printing and",
  //   "typesetting industry."
  // ];
}
