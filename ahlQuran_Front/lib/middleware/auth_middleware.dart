import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated by checking ProfileController
    try {
      final profileController = Get.find<ProfileController>();

      // CRITICAL: If profile is not ready yet, allow navigation
      // This prevents redirect to login during page reload
      // The profile data is being loaded from storage asynchronously
      if (!profileController.isReady.value) {
        // Schedule a check after profile is loaded
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!profileController.isReady.value) {
            // Still not ready, wait a bit more
            Future.delayed(const Duration(milliseconds: 400), () {
              _checkAuthAfterLoad(profileController, route);
            });
          } else {
            _checkAuthAfterLoad(profileController, route);
          }
        });
        return null; // Allow navigation for now
      }

      // Profile is ready, check authentication
      return _checkAuth(profileController);
    } catch (e) {
      // ProfileController not found, allow navigation
      // It will be initialized by StarterBinding
      return null;
    }
  }

  RouteSettings? _checkAuth(ProfileController profileController) {
    // Check both userName and token for authentication
    bool isAuthenticated = profileController.userName.value.isNotEmpty ||
        profileController.token.value.isNotEmpty;

    if (!isAuthenticated) {
      return const RouteSettings(name: Routes.logIn);
    }
    return null;
  }

  void _checkAuthAfterLoad(ProfileController profileController, String? route) {
    if (!profileController.isReady.value) {
      return; // Still not ready, give up
    }

    bool isAuthenticated = profileController.userName.value.isNotEmpty ||
        profileController.token.value.isNotEmpty;

    if (!isAuthenticated && route != Routes.logIn) {
      // User is not authenticated, redirect to login
      Get.offAllNamed(Routes.logIn);
    }
  }
}
