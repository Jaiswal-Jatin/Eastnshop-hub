import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:developer';

import '../Utils/ApiService.dart';
import '../Utils/RefreshService.dart';


class NearbyOffersController extends GetxController {
  // Observable variables
  final RxList<Map<String, dynamic>> nearbyOffers = <Map<String, dynamic>>[].obs;
  final RxMap<String, List<Map<String, dynamic>>> groupedOffers = <String, List<Map<String, dynamic>>>{}.obs;
  final RxBool isLoadingOffers = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString locationError = ''.obs;
  final RxString apiError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize location and fetch offers when controller is created
    getCurrentLocationAndOffers();
    
    // Listen to global refresh events
    ever(RefreshService.to.refreshTrigger, (int trigger) {
      log("🔄 NearbyOffersController: Received refresh trigger $trigger");
      refreshOffers();
    });
  }

  // Get current location and fetch nearby offers
  Future<void> getCurrentLocationAndOffers() async {
    try {
      isLoadingLocation.value = true;
      locationError.value = '';
      apiError.value = '';

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'Location services are disabled. Please enable location services.';
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Location permissions are denied. Please allow location access.';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permissions are permanently denied. Please enable in settings.';
        return;
      }

      // Try to get current position with fallback strategy
      Position? position;
      
      try {
        // First try with medium accuracy and longer timeout
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (e) {
        log('First location attempt failed: $e');
        
        try {
          // Fallback to low accuracy with shorter timeout
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e2) {
          log('Second location attempt failed: $e2');
          
          try {
            // Last resort: get last known position
            position = await Geolocator.getLastKnownPosition();
            if (position == null) {
              throw Exception('No location data available');
            }
          } catch (e3) {
            log('Last known position also failed: $e3');
            throw Exception('Unable to get location. Please check your GPS settings.');
          }
        }
      }

      if (position != null) {
        currentPosition.value = position;
        log('Current location: ${position.latitude}, ${position.longitude}');

        // Fetch nearby offers
        await fetchNearbyOffers(position.latitude, position.longitude);
      } else {
        locationError.value = 'Unable to get location. Please check your GPS settings.';
      }

    } catch (e) {
      log('Error getting location: $e');
      locationError.value = 'Error getting location: ${e.toString()}';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  // Fetch nearby offers from API
  Future<void> fetchNearbyOffers(double lat, double lng) async {
    try {
      isLoadingOffers.value = true;
      apiError.value = '';

      final response = await ApiService.get(
        '/api/offer/nearby?lat=$lat&lng=$lng',
        includeAuth: false,
      );

      log('Nearby offers API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Process the grouped offers response
          Map<String, List<Map<String, dynamic>>> processedGroupedOffers = {};
          List<Map<String, dynamic>> allOffers = [];
          
          data.forEach((offerType, offersList) {
            if (offersList is List) {
              List<Map<String, dynamic>> processedOffers = [];
              for (var offer in offersList) {
                Map<String, dynamic> processedOffer = Map<String, dynamic>.from(offer);
                
                // Round distance_m to whole number if it exists
                if (processedOffer['distance_m'] != null) {
                  final distanceInMeters = processedOffer['distance_m'];
                  if (distanceInMeters is num) {
                    processedOffer['distance_m'] = distanceInMeters.round();
                  }
                }
                
                processedOffers.add(processedOffer);
                allOffers.add(processedOffer);
              }
              processedGroupedOffers[offerType] = processedOffers;
            }
          });
          
          groupedOffers.value = processedGroupedOffers;
          nearbyOffers.value = allOffers;
          log('Loaded ${allOffers.length} nearby offers grouped into ${processedGroupedOffers.length} categories');
        } else if (data is List) {
          // Fallback for old API format
          List<Map<String, dynamic>> processedOffers = [];
          for (var offer in data) {
            Map<String, dynamic> processedOffer = Map<String, dynamic>.from(offer);
            
            // Round distance_m to whole number if it exists
            if (processedOffer['distance_m'] != null) {
              final distanceInMeters = processedOffer['distance_m'];
              if (distanceInMeters is num) {
                processedOffer['distance_m'] = distanceInMeters.round();
              }
            }
            
            processedOffers.add(processedOffer);
          }
          
          nearbyOffers.value = processedOffers;
          log('Loaded ${nearbyOffers.length} nearby offers (legacy format)');
        } else {
          nearbyOffers.value = [];
          groupedOffers.value = {};
          log('API returned unexpected data format: $data');
        }
      } else {
        apiError.value = 'Failed to load offers: ${response.statusCode}';
        nearbyOffers.value = [];
        log('Error fetching nearby offers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      nearbyOffers.value = [];
      groupedOffers.value = {};
      if (e.toString().contains('TimeoutException')) {
        apiError.value = 'Request timed out. Please check your internet connection.';
        log('Timeout fetching nearby offers: $e');
      } else if (e.toString().contains('SocketException')) {
        apiError.value = 'Network error. Please check your internet connection.';
        log('Network error fetching nearby offers: $e');
      } else {
        apiError.value = 'Error loading offers: ${e.toString()}';
        log('Exception fetching nearby offers: $e');
      }
    } finally {
      isLoadingOffers.value = false;
    }
  }

  // Refresh nearby offers
  Future<void> refreshOffers() async {
    if (currentPosition.value != null) {
      await fetchNearbyOffers(
        currentPosition.value!.latitude, 
        currentPosition.value!.longitude
      );
    } else {
      await getCurrentLocationAndOffers();
    }
  }

  // Get formatted distance
  String getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Get offer by ID
  Map<String, dynamic>? getOfferById(String offerId) {
    try {
      return nearbyOffers.firstWhere(
        (offer) => offer['id']?.toString() == offerId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if offers are available
  bool get hasOffers => nearbyOffers.isNotEmpty;
  
  // Get offers by type
  List<Map<String, dynamic>> getOffersByType(String offerType) {
    return groupedOffers[offerType] ?? [];
  }
  
  // Get all offer types
  List<String> get offerTypes => groupedOffers.keys.toList();

  // Check if there are any errors
  bool get hasError => locationError.value.isNotEmpty || apiError.value.isNotEmpty;

  // Get combined error message
  String get errorMessage {
    if (locationError.value.isNotEmpty) return locationError.value;
    if (apiError.value.isNotEmpty) return apiError.value;
    return '';
  }

  // Clear all errors
  void clearErrors() {
    locationError.value = '';
    apiError.value = '';
  }

  // Force refresh location and offers
  Future<void> forceRefresh() async {
    clearErrors();
    await getCurrentLocationAndOffers();
  }

  // Manual location input as fallback
  Future<void> setManualLocation(double lat, double lng) async {
    try {
      // Store coordinates and fetch offers directly
      locationError.value = '';
      await fetchNearbyOffers(lat, lng);
    } catch (e) {
      log('Error setting manual location: $e');
      apiError.value = 'Error fetching offers for location: ${e.toString()}';
    }
  }

  // Use default location (Mumbai) as fallback
  Future<void> useDefaultLocation() async {
    const double defaultLat = 19.0760; // Mumbai
    const double defaultLng = 72.8777;
    await setManualLocation(defaultLat, defaultLng);
  }
}
