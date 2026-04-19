import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class CommonUtils {
  static Future<bool> hasInternetConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.none)) {
      return false;
    }

    // Try to make a DNS lookup to confirm internet access
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }

    return false;
  }
}
