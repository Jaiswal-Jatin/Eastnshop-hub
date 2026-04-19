import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../Utils/ApiService.dart';
import '../Utils/ImageCacheHelper.dart';
import '../Utils/RefreshService.dart';

class HomeDataController extends GetxController {
  // Carousel images
  var carouselImages = <Map<String, dynamic>>[].obs;
  var isLoadingCarousel = false.obs;
  var hasCarouselError = false.obs;

  // Middle banner
  var middleBannerImage = Rxn<Map<String, dynamic>>();
  var isLoadingMiddleBanner = false.obs;
  var hasMiddleBannerError = false.obs;

  // Bottom banner
  var bottomBannerImage = Rxn<Map<String, dynamic>>();
  var isLoadingBottomBanner = false.obs;
  var hasBottomBannerError = false.obs;

  // Overall loading status
  var isPreloading = false.obs;

  /// Normalize URL: convert http to https
  String _normalizeUrl(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// Fetches all home screen data
  Future<void> fetchAllHomeData(BuildContext context) async {
    if (isPreloading.value) return;

    try {
      isPreloading.value = true;
      print('🚀 Starting home data loading...');

      // Run all fetches in parallel
      await Future.wait([
        _loadCarouselImages(),
        _loadMiddleBannerImage(),
        _loadBottomBannerImage(),
      ]);

      print('✅ All home data loaded!');

      // Pre-cache images to disk in background (no context needed!)
      _preCacheImagesToDisk();
    } catch (e) {
      print('❌ Error during home data loading: $e');
    } finally {
      isPreloading.value = false;
    }
  }

  /// Pre-cache all loaded image URLs to disk for instant loading next time
  void _preCacheImagesToDisk() {
    final urls = <String>[];
    for (var img in carouselImages) {
      if (img['url'] != null && img['url'].toString().isNotEmpty) {
        urls.add(img['url']);
      }
    }
    if (middleBannerImage.value != null && middleBannerImage.value!['url'] != null) {
      urls.add(middleBannerImage.value!['url']);
    }
    if (bottomBannerImage.value != null && bottomBannerImage.value!['url'] != null) {
      urls.add(bottomBannerImage.value!['url']);
    }
    if (urls.isNotEmpty) {
      ImageCacheService().preCacheUrls(urls);
    }
  }

  Future<void> _loadCarouselImages() async {
    try {
      isLoadingCarousel.value = true;
      hasCarouselError.value = false;

      final images = await ApiService.getMediaImages();

      // Normalize all URLs to HTTPS
      final normalized = images.map((img) {
        if (img['url'] != null) {
          img['url'] = _normalizeUrl(img['url']);
        }
        return img;
      }).toList();

      carouselImages.assignAll(normalized);
      hasCarouselError.value = normalized.isEmpty;
    } catch (e) {
      hasCarouselError.value = true;
      print('Error loading carousel: $e');
    } finally {
      isLoadingCarousel.value = false;
    }
  }

  Future<void> _loadMiddleBannerImage() async {
    try {
      isLoadingMiddleBanner.value = true;
      hasMiddleBannerError.value = false;

      final imageData = await ApiService.getImage1();
      if (imageData != null && imageData['url'] != null) {
        imageData['url'] = _normalizeUrl(imageData['url']);
      }
      middleBannerImage.value = imageData;

      hasMiddleBannerError.value = imageData == null;
    } catch (e) {
      hasMiddleBannerError.value = true;
      print('Error loading middle banner: $e');
    } finally {
      isLoadingMiddleBanner.value = false;
    }
  }

  Future<void> _loadBottomBannerImage() async {
    try {
      isLoadingBottomBanner.value = true;
      hasBottomBannerError.value = false;

      final imageData = await ApiService.getImage2();
      if (imageData != null && imageData['url'] != null) {
        imageData['url'] = _normalizeUrl(imageData['url']);
      }
      bottomBannerImage.value = imageData;

      hasBottomBannerError.value = imageData == null;
    } catch (e) {
      hasBottomBannerError.value = true;
      print('Error loading bottom banner: $e');
    } finally {
      isLoadingBottomBanner.value = false;
    }
  }
  @override
  void onInit() {
    super.onInit();
    // Listen for global refresh triggers
    ever(RefreshService.to.refreshTrigger, (_) {
      print('🔄 HomeDataController: Refresh triggered, reloading data...');
      fetchAllHomeData(Get.context!);
    });
  }
}
