import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Show a success snackbar using GetX Snackbar (appears above dialogs)
void showSuccessSnackbar(String message, {BuildContext? context}) {
  try {
    Get.rawSnackbar(
      title: 'نجح',
      message: message,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      backgroundColor: Colors.green.shade600,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      shouldIconPulse: false,
      barBlur: 0,
    );
  } catch (e) {
    debugPrint('Error showing success snackbar: $e');
  }
}

/// Show an error snackbar using GetX Snackbar (appears above dialogs)
void showErrorSnackbar(String message, {BuildContext? context}) {
  try {
    Get.rawSnackbar(
      title: 'خطأ',
      message: message,
      icon: const Icon(Icons.error, color: Colors.white),
      backgroundColor: Colors.red.shade600,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      shouldIconPulse: false,
      barBlur: 0,
    );
  } catch (e) {
    debugPrint('Error showing error snackbar: $e');
  }
}

/// Show an info snackbar using GetX Snackbar (appears above dialogs)
void showInfoSnackbar(String message, {BuildContext? context}) {
  try {
    Get.rawSnackbar(
      title: 'معلومة',
      message: message,
      icon: const Icon(Icons.info, color: Colors.white),
      backgroundColor: Colors.blue.shade600,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      shouldIconPulse: false,
      barBlur: 0,
    );
  } catch (e) {
    debugPrint('Error showing info snackbar: $e');
  }
}
