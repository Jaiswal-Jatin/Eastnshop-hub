import 'package:get/get.dart';

import '../Utils/SharedPrefUtils.dart';

// Global variables for the app
RxBool globalUser = true.obs;
RxBool isShopkeeper = false.obs;
String globalesettings = "false";

// Make sure the variables are accessible
void updateGlobalSettings(String value) {
  globalesettings = value;
}

String getGlobalSettings() {
  return globalesettings;
}

// Helper function to initialize global state from SharedPreferences
Future<void> initializeGlobalState() async {
  await SharedPrefUtils.init();
  String? userRole = SharedPrefUtils.getString('user_role');
  String? viewMode = SharedPrefUtils.getString('view_mode'); // 'user' or 'shop'
  
  if (userRole != null) {
    isShopkeeper.value = userRole == 'shopkeeper';
    if (isShopkeeper.value) {
      // For shopkeepers, prefer persisted view mode if present
      if (viewMode == 'user') {
        globalUser.value = true;
      } else if (viewMode == 'shop') {
        globalUser.value = false;
      } else {
        // Default to shopkeeper view
        globalUser.value = false;
      }
    } else {
      // Non-shopkeepers are always user view
      globalUser.value = true;
    }
  } else {
    // Default state when no user role is found
    isShopkeeper.value = false;
    globalUser.value = true;
  }
}

// Helper function to reset global state
void resetGlobalState() {
  isShopkeeper.value = false;
  globalUser.value = true;
}

// Helper function to switch between user and shopkeeper views
Future<void> switchUserRole() async {
  await SharedPrefUtils.init();
  String? userRole = SharedPrefUtils.getString('user_role');
  
  print("🔄 Role switch requested - Current role: $userRole, globalUser: ${globalUser.value}, isShopkeeper: ${isShopkeeper.value}");
  
  if (userRole == 'shopkeeper') {
    // Toggle between user and shopkeeper view
    if (globalUser.value == true) {
      // Currently in user view, switch to shopkeeper view
      globalUser.value = false;
      await SharedPrefUtils.setString('view_mode', 'shop');
      print("✅ Switching from User to Shopkeeper view - globalUser: ${globalUser.value}");
    } else {
      // Currently in shopkeeper view, switch to user view
      globalUser.value = true;
      await SharedPrefUtils.setString('view_mode', 'user');
      print("✅ Switching from Shopkeeper to User view - globalUser: ${globalUser.value}");
    }
  } else {
    print("❌ User is not a shopkeeper, cannot switch roles");
  }
}
