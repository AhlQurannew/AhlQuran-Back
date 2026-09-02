import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart'; // Make sure this import path matches your file structure

enum AuthStatus { signedIn, signedOut }

class AuthController extends GetxController {
  // Initialize FlutterSecureStorage
  final _storage = const FlutterSecureStorage();

  // Reactive variable to track if the user is signed in
  var isSignedIn = false.obs;

  // Keys for storing user data
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';

  @override
  void onInit() {
    super.onInit();
    checkSignInStatus();
  }

  // Check if the user is signed in by reading from secure storage
  Future<void> checkSignInStatus() async {
    String? token = await _storage.read(key: _tokenKey);
    isSignedIn.value = token != null && token.isNotEmpty;
  }

  // Handle sign-in: Store user data and show snackbar
  Future<void> signIn({
    required String token,
    required String userName,
    required BuildContext context,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userNameKey, value: userName);
      isSignedIn.value = true;

      showSuccessSnackbar('تم تسجيل الدخول بنجاح!');
    } catch (e) {
      showErrorSnackbar('فشل تسجيل الدخول. حاول مرة أخرى.');
    }
  }

  // Handle sign-out: Clear storage and show snackbar
  Future<void> signOut(BuildContext context) async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userNameKey);
      isSignedIn.value = false;

      showInfoSnackbar('تم تسجيل الخروج!');
    } catch (e) {
      showErrorSnackbar('فشل تسجيل الخروج. حاول مرة أخرى.');
    }
  }

  // Get stored user name
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
