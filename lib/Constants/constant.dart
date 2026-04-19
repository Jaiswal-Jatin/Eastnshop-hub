
import 'package:flutter/material.dart';

import '../Screen/AdminPanel/ShopDetails/AddShop.dart';
import '../Screen/DrawerScreen.dart';
import 'app_colors.dart';


   int selectedIndex = 0;
 allAppBar(BuildContext context){
  return PreferredSize(
    preferredSize: Size.fromHeight(70), 
    child: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Removes default back button
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DrawerScreen()),
                    ),
                    child: Image.asset('assets/menu.png'),
                  ),
                  SizedBox(width: 10),
                  Image.asset(
                    'assets/Shopkeeper_logo.png',
                    height: 50,
                    width: 50,
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddShop()),
                    ),
                    child: Image.asset(
                             'assets/location.png',
                             height: 40,
                             width: 40,
                             color: AppColors.greyText,
                           ),
                  ),
                  SizedBox(width: 5),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey.shade200,
                    ),
                    child: Image.asset("assets/profile-man.png"),
                  ),
                ],
              ),
              Divider(color: Colors.grey),
            ],
          ),
        ),
      ),
    ),
  );
}
