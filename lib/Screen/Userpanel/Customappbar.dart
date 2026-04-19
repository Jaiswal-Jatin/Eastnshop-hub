 import 'package:flutter/material.dart';

import '../AdminPanel/Notification/AdminNotification.dart';
class CustomAppBarWithDrawer extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarWithDrawer({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // Disable default back button
        titleSpacing: 0, // Remove left padding
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              'assets/Shopkeeper_logo.png',
              height: 40,
              width: 40,
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopkeeperNotificationScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                'assets/notification.png',
                height: 30,
                width: 30,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
  }
}
