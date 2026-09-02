import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class PresidentMiddleware extends GetMiddleware {
  @override
  int? get priority => 2; // Higher priority than AuthMiddleware

  @override
  RouteSettings? redirect(String? route) {
    try {
      final profileController = Get.find<ProfileController>();

      // Wait for profile to be ready
      if (!profileController.isReady.value) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!profileController.isReady.value) {
            Future.delayed(const Duration(milliseconds: 400), () {
              _checkRoleAfterLoad(profileController, route);
            });
          } else {
            _checkRoleAfterLoad(profileController, route);
          }
        });
        return null;
      }

      // Profile is ready, check role
      return _checkRole(profileController);
    } catch (e) {
      // ProfileController not found, redirect to login
      return const RouteSettings(name: Routes.logIn);
    }
  }

  RouteSettings? _checkRole(ProfileController profileController) {
    final userRole = profileController.userRole.value.toLowerCase();

    // Allow access only for presidents and admins
    if (userRole != 'president' && userRole != 'admin') {
      // Redirect to dashboard if not authorized
      return const RouteSettings(name: Routes.dashboardPage);
    }

    return null;
  }

  void _checkRoleAfterLoad(ProfileController profileController, String? route) {
    if (!profileController.isReady.value) {
      return;
    }

    final userRole = profileController.userRole.value.toLowerCase();

    if (userRole != 'president' && userRole != 'admin') {
      Get.offAllNamed(Routes.dashboardPage);
    }
  }
}
