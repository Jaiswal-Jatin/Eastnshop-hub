
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import '../Bindings/Bindings.dart';
import '../Screen/AdminPanel/ActiveOffer.dart';
import '../Screen/AdminPanel/AdminDashboard/HomePage.dart';
import '../Screen/AdminPanel/EditOffer/EditOfferPage.dart';
import '../Screen/AdminPanel/InactiveOffersPage.dart';
import '../Screen/LoadingScreen.dart';
import '../Screen/Login/Login.dart';
import '../Screen/Login/SignUp.dart';
import '../Screen/SplashScreen.dart';
import '../Screen/Userpanel/ActivePlansScreen.dart';
import '../Screen/Userpanel/OfferDetailsPage.dart';
import '../Screen/Userpanel/SpecialPlansScreen.dart';
import '../Screen/Userpanel/UserDashboard/FavoritesPage.dart';
import '../Screen/Userpanel/UserDashboard/UserHome.dart';

abstract class AppRoutes {
  static const domainName = "https://eastnshoptech.cloud";
  static const splash = '/';
  static const appStart = '/loading';
  static const signUp = "/SignUp";
  static const login = "/login";
  static const dashboard = "/dashboard";
  static const home = "/home";
  static const shopkeeperHome = "/shopkeeper-home";
  static const favorites = "/favorites";
  static const offerDetails = "/offer-details";
  static const specialPlans = "/special-plans";
  static const activePlans = "/active-plans";
  static const editOffer = "/edit-offer";
  static const activeOffers = "/active-offers";
  static const inactiveOffers = "/inactive-offers";
}

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.appStart,
      page: () => Loadingscreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => Signup(),
      binding: SignUpBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => Home(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.shopkeeperHome,
      page: () => const HomePage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.offerDetails,
      page: () => OfferDetailsPage(offerId: Get.parameters['id'] ?? '1'),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.editOffer,
      page: () => EditOfferPage(offer: Get.arguments),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.specialPlans,
      page: () => const SpecialPlansScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.activePlans,
      page: () => const ActivePlansScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.activeOffers,
      page: () => const ActiveOffersPage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.inactiveOffers,
      page: () => const InactiveOffersPage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),

  
  ];
}
