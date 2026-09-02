import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController {
  final avatarPath = 'assets/avatar.png'.obs;
  final userName = ''.obs;
  final firstName = ''.obs;
  final lastName = ''.obs;
  final userRole = ''.obs;
  final userEmail = ''.obs;
  final userId = Rxn<int>();
  final token = ''.obs;
  final refreshToken = ''.obs;
  final isReady = false.obs;

  // Storage with fallback mechanism
  late FlutterSecureStorage _storage;
  SharedPreferences? _prefs;
  bool _isStorageInitialized = false;
  bool _useSecureStorage = false;

  @override
  void onInit() {
    super.onInit();
    _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      // Initialize SharedPreferences first (always works)
      _prefs = await SharedPreferences.getInstance();

      // Disable secure storage on Windows to avoid credential manager issues
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint(
            'Windows detected: Using SharedPreferences instead of secure storage');
        _useSecureStorage = false;
        _isStorageInitialized = true;
        await fetchUserProfile();
        return;
      }

      // Try to initialize secure storage for other platforms
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

      // Test if secure storage works
      try {
        await _storage.write(key: '_test', value: 'test');
        await _storage.delete(key: '_test');
        _useSecureStorage = true;
        debugPrint('Secure storage initialized successfully');
      } catch (testError) {
        debugPrint(
            'Secure storage failed, using SharedPreferences: $testError');
        _useSecureStorage = false;
      }

      _isStorageInitialized = true;
      await fetchUserProfile();
    } catch (e) {
      debugPrint('Storage initialization error: $e');
      _isStorageInitialized = false;
    }
  }

  Future<String?> _readValue(String key) async {
    try {
      if (_useSecureStorage) {
        return await _storage.read(key: key);
      } else {
        return _prefs?.getString(key);
      }
    } catch (e) {
      debugPrint('Error reading $key with secure storage, trying fallback: $e');
      // Try fallback to SharedPreferences
      try {
        return _prefs?.getString(key);
      } catch (fallbackError) {
        debugPrint('Fallback storage also failed for $key: $fallbackError');
        return null;
      }
    }
  }

  Future<void> fetchUserProfile() async {
    if (!_isStorageInitialized) {
      isReady.value = true;
      return;
    }

    try {
      final storedFirstName = await _readValue('firstName');
      final storedLastName = await _readValue('lastName');
      final storedUserName = await _readValue('userName');
      final storedEmail = await _readValue('userEmail');
      final storedRole = await _readValue('userRole');
      final storedUserId = await _readValue('userId');
      final storedAvatar = await _readValue('avatarPath');
      final storedToken = await _readValue('token');
      final storedRefreshToken = await _readValue('refreshToken');

      if (storedFirstName != null) firstName.value = storedFirstName;
      if (storedLastName != null) lastName.value = storedLastName;
      if (storedUserName != null) userName.value = storedUserName;
      if (storedEmail != null) userEmail.value = storedEmail;
      if (storedRole != null) userRole.value = storedRole;
      if (storedUserId != null) userId.value = int.tryParse(storedUserId);
      if (storedAvatar != null) avatarPath.value = storedAvatar;
      if (storedToken != null) token.value = storedToken;
      if (storedRefreshToken != null) refreshToken.value = storedRefreshToken;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      isReady.value = true;
    }
  }

  Future<void> updateProfile({
    required String avatar,
    required String name,
    required String role,
    String? email,
    String? first,
    String? last,
    int? id,
    String? accessToken,
    String? refreshTokenValue,
  }) async {
    // CRITICAL: Update in-memory values FIRST before any storage operations
    // This ensures app works even if storage fails
    avatarPath.value = avatar;
    userName.value = name;
    userRole.value = role;
    if (email != null) userEmail.value = email;
    if (first != null) firstName.value = first;
    if (last != null) lastName.value = last;
    if (id != null) userId.value = id;
    if (accessToken != null && accessToken.isNotEmpty) {
      token.value = accessToken;
    }
    if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
      refreshToken.value = refreshTokenValue;
    }

    // Try to save to secure storage
    if (!_isStorageInitialized) {
      debugPrint('Storage not initialized, skipping persistence');
      return;
    }

    try {
      await _writeValue('avatarPath', avatar);
      await _writeValue('userName', name);
      await _writeValue('userRole', role);
      if (email != null) await _writeValue('userEmail', email);
      if (first != null) await _writeValue('firstName', first);
      if (last != null) await _writeValue('lastName', last);
      if (id != null) await _writeValue('userId', id.toString());

      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('Saving token (length: ${accessToken.length})');
        await _writeValue('token', accessToken);
        debugPrint('Token saved successfully');
      }

      if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
        debugPrint(
            'Saving refresh token (length: ${refreshTokenValue.length})');
        await _writeValue('refreshToken', refreshTokenValue);
        debugPrint('Refresh token saved successfully');
      }

      debugPrint('Profile saved successfully');
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  Future<void> _writeValue(String key, String value) async {
    try {
      if (_useSecureStorage) {
        await _storage.write(key: key, value: value);
      } else {
        await _prefs?.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error writing $key with secure storage, using fallback: $e');
      // Force fallback to SharedPreferences on error
      try {
        await _prefs?.setString(key, value);
      } catch (fallbackError) {
        debugPrint('Fallback storage also failed for $key: $fallbackError');
        // Silently fail - app will continue working with in-memory values
      }
    }
  }

  Future<void> clearProfile() async {
    // Clear in-memory values
    avatarPath.value = 'assets/avatar.png';
    userName.value = '';
    firstName.value = '';
    lastName.value = '';
    userRole.value = '';
    userEmail.value = '';
    userId.value = null;
    token.value = '';
    refreshToken.value = '';

    // Clear storage
    if (_isStorageInitialized) {
      try {
        if (_useSecureStorage) {
          await _storage.deleteAll();
        }
        await _prefs?.clear();
      } catch (e) {
        debugPrint('Error clearing storage: $e');
      }
    }
  }
}
