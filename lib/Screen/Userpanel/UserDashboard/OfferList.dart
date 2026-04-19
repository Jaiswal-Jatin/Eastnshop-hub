
import 'package:flutter/material.dart';

import '../../AdminPanel/Notification/AdminNotification.dart';
import '../../DrawerScreen.dart';
import '../OfferDetailsPage.dart';

class OfferListPage extends StatelessWidget {
  final List<Map<String, String>> products = [
    {
      'id': '1',
      'image': 'assets/smartwatch.png',
      'title': 'Cellecor E6 Shift',
      'discount': '23%',
      'oldPrice': '₹16,999',
      'newPrice': '₹12,999',
    },
    {
      'id': '2',
      'image': 'assets/earbuds.png',
      'title': 'Cellecor E6 Shift',
      'discount': '23%',
      'oldPrice': '₹16,999',
      'newPrice': '₹12,999',
    },
    {
      'id': '3',
      'image': 'assets/earbuds.png',
      'title': 'Cellecor E6 Shift',
      'discount': '23%',
      'oldPrice': '₹16,999',
      'newPrice': '₹12,999',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.grey[100],
       drawer: const DrawerScreen(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 0, // Removes default left padding
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/Shopkeeper_logo.png',
              height: 50,
              width: 50,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search best offers",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              // Replace with your navigation
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopkeeperNotificationScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Image.asset(
                'assets/notification.png',
                height: 26,
                width: 26,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          "Offer Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
  ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(products.length, (index) {
          final product = products[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      product['image']!,
                      width: 150,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "↓${product['discount']!}",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product['oldPrice']!,
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product['newPrice']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OfferDetailsPage(
                                  offerId: product['id'] ?? '1', // Use product ID or default
                                ),
                              ),
                            );
                          },
                          child: const Text("View details", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
            ],
          );
        }),

      ],
    ),
  ),
),
    );
  }
}
