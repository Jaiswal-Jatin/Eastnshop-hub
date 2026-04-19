import 'dart:ui';

 import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_colors.dart';

class CommonWidgets {

 static Future<void> CustomeSnackBar({required String title,required String message,required backgroundColor})async {
   Get.snackbar(title, message,backgroundColor: backgroundColor,snackPosition: SnackPosition.TOP);
 }

}

enum SnackType { error, warning, info, success }

class AppSnackBar {
  static void show({
    required String message,
    SnackType type = SnackType.info,
    String? title,
  }) {
    Color bgColor;
    String snackTitle;

    switch (type) {
      case SnackType.error:
        bgColor = AppColors.primaryRed;
        snackTitle = title ?? "Error";
        break;
      case SnackType.warning:
        bgColor = Colors.orange;
        snackTitle = title ?? "Warning";
        break;
      case SnackType.info:
        bgColor = Colors.blueGrey;
        snackTitle = title ?? "Info";
        break;
      case SnackType.success:
        bgColor = Colors.green;
        snackTitle = title ?? "Success";
        break;
    }

    CommonWidgets.CustomeSnackBar(
      title: snackTitle,
      message: message,
      backgroundColor: bgColor,
    );
  }
}
