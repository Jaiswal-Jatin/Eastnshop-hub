import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Constants/GlobalVariables.dart';
import '../Routes/App_Pages.dart';
import '../Utils/SharedPrefUtils.dart';
import '../Utils/TokenManager.dart';

class Loadingscreen extends StatefulWidget {
  const Loadingscreen({super.key});

  @override
  State<Loadingscreen> createState() => _LoadingscreenState();
}

class _LoadingscreenState extends State<Loadingscreen> {

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final bool isAuthenticated = await TokenManager.isAuthenticated();
      final String? userRole = SharedPrefUtils.getString('user_role');

      debugPrint(
        "Auth check → isAuthenticated: $isAuthenticated, role: $userRole",
      );

      if (!mounted) return;

      if (isAuthenticated) {
        await initializeGlobalState();

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.shopkeeperHome);
        // if (isShopkeeper.value) {
        //   Get.offAllNamed(AppRoutes.shopkeeperHome);
        // } else {
        //   Get.offAllNamed(AppRoutes.home);
        // }
      } else {
        await TokenManager.clearTokens();
        await SharedPrefUtils.setBool('is_logged_in', false);
        resetGlobalState();
      }
    } catch (e, stack) {
      debugPrint("Auth check error: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [

          SizedBox.expand(
            child: Image.asset(
              'assets/shopsplash.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔥 CONTENT OVER IMAGE
          Positioned(
            bottom: height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.signUp),
                  child: Container(
                    height: 50,
                    width: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: [
                    const Text(
                      'Already have account?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Text('|', style: TextStyle(color: Colors.white)),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.login),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
