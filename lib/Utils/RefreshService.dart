import 'package:get/get.dart';
import 'dart:developer';

/// Global service to trigger data refresh across the app
class RefreshService extends GetxService {
  static RefreshService get to => Get.find();
  
  // Observable to trigger refresh events
  final RxInt refreshTrigger = 0.obs;
  
  // Trigger refresh for all pages
  void triggerRefresh() {
    refreshTrigger.value++;
    log("🔄 RefreshService: Triggering global refresh (trigger: ${refreshTrigger.value})");
  }
  
  // Trigger refresh for specific page types
  void triggerShopRefresh() {
    refreshTrigger.value++;
    log("🔄 RefreshService: Triggering shop data refresh (trigger: ${refreshTrigger.value})");
  }
  
  void triggerOfferRefresh() {
    refreshTrigger.value++;
    log("🔄 RefreshService: Triggering offer data refresh (trigger: ${refreshTrigger.value})");
  }

  void triggerPlanRefresh() {
    refreshTrigger.value++;
    log("🔄 RefreshService: Triggering plan/subscription data refresh (trigger: ${refreshTrigger.value})");
  }
  
  @override
  void onInit() {
    super.onInit();
    log("🔄 RefreshService initialized");
  }
}
