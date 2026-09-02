class ApiConfig {
  // IMPORTANT: Choose the right URL based on your device:

  // Option 1: Android Emulator (use this for Android Studio emulator)
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // Option 2: iOS Simulator (use this for Xcode simulator)
  // static const String baseUrl = 'http://localhost:8000';

  // Option 3: Physical Device (use your computer's IP address)
  static const String baseUrl = 'http://172.20.10.4:8000';

  // Option 4: Production
  // static const String baseUrl = 'https://your-backend-domain.com';

  static const String apiVersion = '/api/v1';

  static String get authBaseUrl => '$baseUrl$apiVersion/auth';
  static String get guardianBaseUrl => '$baseUrl$apiVersion/guardians';
}
