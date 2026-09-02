import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guardian.dart';
import 'api_config.dart';

class AuthService {
  Future<LoginResponse> guardianLogin(String email, String password) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}/guardian/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Save token and login data to shared preferences
        await _saveToken(loginResponse.accessToken);
        await _saveLoginData(loginResponse);

        return loginResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Account is inactive. Please contact the administrator.',
        );
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> _saveLoginData(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final loginDataJson = jsonEncode({
      'access_token': loginResponse.accessToken,
      'token_type': loginResponse.tokenType,
      'message': loginResponse.message,
      'user': {
        'id': loginResponse.user.id,
        'email': loginResponse.user.email,
        'firstname': loginResponse.user.firstname,
        'lastname': loginResponse.user.lastname,
        'role': loginResponse.user.role,
        'is_active': loginResponse.user.isActive,
      },
      'guardian': loginResponse.guardian != null
          ? {
              'guardian_id': loginResponse.guardian!.id,
              'first_name': loginResponse.guardian!.firstName,
              'last_name': loginResponse.guardian!.lastName,
              'relationship': loginResponse.guardian!.relationship,
            }
          : null,
    });
    await prefs.setString('login_data', loginDataJson);
    print('Login data saved successfully'); // Debug log
  }

  Future<LoginResponse?> getStoredLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final loginDataJson = prefs.getString('login_data');

    print(
      'Retrieving login data: ${loginDataJson != null ? "Found" : "Not found"}',
    ); // Debug log

    if (loginDataJson != null) {
      try {
        final data = jsonDecode(loginDataJson);
        print('Login data decoded successfully'); // Debug log
        return LoginResponse.fromJson(data);
      } catch (e) {
        print('Error decoding login data: $e'); // Debug log
        return null;
      }
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('login_data');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
