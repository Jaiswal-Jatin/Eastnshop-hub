import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/HomeDataController.dart';

import '../Constants/GlobalVariables.dart';
import '../Routes/App_Pages.dart';
import '../Utils/SharedPrefUtils.dart';
import '../Utils/TokenManager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _fadeTextAnimation;

  static const Color growthGreen = Color(0xFF00C853);
  static const Color trustBlue = Color(0xFF0066CC);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 22,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeTextAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _navigateAfterDelay();
  }

  /// ---------------- NAVIGATION LOGIC (UNCHANGED) ----------------
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 4));

    await SharedPrefUtils.init();
    final bool isAuthenticated = await TokenManager.isAuthenticated();

    // Initialize and trigger home data pre-loading if authenticated
    if (isAuthenticated) {
      if (!Get.isRegistered<HomeDataController>()) {
        Get.put(HomeDataController());
      }
      final homeController = Get.find<HomeDataController>();

      // Start pre-loading images in parallel with the remain splash delay
      // Using context from this state to perform precacheImage
      if (mounted) {
        homeController.fetchAllHomeData(context);
        print('🕒 Splash: Started home data pre-loading');
      }

      await initializeGlobalState();
      Get.offAllNamed(AppRoutes.shopkeeperHome);
    } else {
      resetGlobalState();
      Get.offAllNamed(AppRoutes.appStart);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// ---------------- LOGO ANIMATION ----------------
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: growthGreen,
                      boxShadow: [
                        BoxShadow(
                          color: growthGreen.withOpacity(0.5),
                          blurRadius: _glowAnimation.value * 2,
                          spreadRadius: _glowAnimation.value,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      height: 175,
                      width: 175,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(26),
                      child: Image.asset(
                        'assets/Shopkeeper_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _fallbackIcon(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// ---------------- TEXT + LOADER ----------------
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height / 2 + 130,
            child: FadeTransition(
              opacity: _fadeTextAnimation,
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      //style: GoogleFonts.poppins(
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      children: const [
                        TextSpan(
                          text: "EASTNSHOP ",
                          style: TextStyle(color: trustBlue),
                        ),
                        TextSpan(
                          text: "HUB",
                          style: TextStyle(color: growthGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Manage. Grow. Succeed.",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(growthGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- FALLBACK ICON ----------------
  Widget _fallbackIcon() {
    return const Icon(Icons.storefront, size: 55, color: growthGreen);
  }
}
