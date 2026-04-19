// import 'package:eastnshop/Screen/AdminPanel/AdminDashboard/HomePage.dart';
// import 'package:eastnshop/Screen/AdminPanel/Notification/AdminNotification.dart'; 
// import 'package:eastnshop/Constants/app_colors.dart';
// import 'package:eastnshop/Screen/Userpanel/Setting.dart/SettingPage.dart'; 
// import 'package:eastnshop/Screen/DrawerScreen.dart';   
// import 'package:eastnshop/Screen/Userpanel/UserDashboard/UserHome.dart'; 
// import 'package:flutter/material.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {

//   int currentTab = 0;

//   // List of widgets for each tab screen
//   final List<Widget> _widgetOptions = [
//     Home(),
//     HomePage(),
//     SettingsScreen(),  
//   ];

//   // Bottom navigation tab change handler
//   void _onItemTapped(int index) {
//     setState(() {
//       currentTab = index;
//     });
//   }
// List<String> titles = ['Home', 'CreateOffer', 'Profile', ];

//   // Shared AppBar
//   @override
//   Widget build(BuildContext context) {
//     // List of icon asset names
//     final List<String> iconAssets = [
//       'assets/Home.png',
//       'assets/CreateOffer.png',
//       'assets/profile-man.png',  
//     ];

 
//     return Scaffold(
//       drawer: const DrawerScreen(),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 2,
//         titleSpacing: 0, // Removes default left padding
//         leading: Builder(
//           builder: (context) => IconButton(
//             icon: const Icon(Icons.menu, color: Colors.black),
//             onPressed: () => Scaffold.of(context).openDrawer(),
//           ),
//         ),
//         title: Row(
//           children: [
//             Image.asset(
//               'assets/logo_chill_offer.png',
//               height: 50,
//               width: 50,
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Container(
//                 height: 38,
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(Icons.search, color: Colors.grey),
//                     SizedBox(width: 6),
//                     Expanded(
//                       child: TextField(
//                         decoration: InputDecoration(
//                           hintText: "Search best offers",
//                           hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
//                           border: InputBorder.none,
//                           isDense: true,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           InkWell(
//             onTap: () {
//               // Replace with your navigation
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const ShopkeeperNotificationScreen()),
//               );
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Image.asset(
//                 'assets/notification.png',
//                 height: 26,
//                 width: 26,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body:Center(child: _widgetOptions.elementAt(currentTab)),
// bottomNavigationBar: BottomAppBar(
//   shape: const CircularNotchedRectangle(),
//   notchMargin: 8,
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceAround,
//     children: <Widget>[
//       IconButton(
//         icon: Image.asset(
//           'assets/Home.png',
//           height: 35,
//           width: 35,
//           color: currentTab == 0 ? Colors.red : Colors.grey,
//         ),
//         onPressed: () => _onItemTapped(0),
//       ),
//       const SizedBox(width: 40), // Leave space for the FAB
//       IconButton(
//         icon: Image.asset(
//           'assets/profile-man.png',
//           height: 35,
//           width: 35,
//           color: currentTab == 2 ? Colors.red : Colors.grey,
//         ),
//         onPressed: () => _onItemTapped(2),
//       ),
//     ],
//   ),
// ),
// floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
// floatingActionButton: GestureDetector(
//   onTap: () => _onItemTapped(1),
//   child: Container(
//     height: 65,
//     width: 65,
//     decoration: BoxDecoration(
//       color: Colors.red,
//       shape: BoxShape.circle,
//       boxShadow: [
//         BoxShadow(
//           color: Colors.red.withOpacity(0.4),
//           blurRadius: 8,
//           offset: const Offset(0, 4),
//         )
//       ],
//     ),
//     child: Center(
//       child: Image.asset(
//         'assets/CreateOffer.png',
//         height: 30,
//         width: 30,
//         color: Colors.white,
//       ),
//     ),
//   ),
// ),

//     );
//   }
// }
