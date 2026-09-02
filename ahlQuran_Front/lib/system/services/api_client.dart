import 'dart:convert';
import 'dart:developer' as code;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';

class NoNetworkException implements Exception {
  final String message;
  NoNetworkException([this.message = 'No network connection']);
  @override
  String toString() => message;
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No actual internet access']);
  @override
  String toString() => message;
}

class ApiService {
  static bool _isRefreshing = false;
  static final List<Function> _refreshQueue = [];

  static Map<String, String> get defaultHeaders {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json; charset=UTF-8',
    };

    try {
      // Try to get token from ProfileController if available
      if (Get.isRegistered<ProfileController>()) {
        final token = Get.find<ProfileController>().token.value;
        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          _log('Auth token added to headers (length: ${token.length})');
        } else {
          _log('WARNING: No auth token available');
        }
      } else {
        _log('WARNING: ProfileController not registered');
      }
    } catch (e) {
      _log('ERROR getting auth token: $e');
    }

    return headers;
  }

  static Uri _buildUri(String endpoint) => Uri.parse(endpoint);

  static void _log(String message) {
    code.log('[ApiService] $message');
  }

  static Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh
      await Future.delayed(const Duration(milliseconds: 100));
      return !_isRefreshing;
    }

    _isRefreshing = true;
    _log('Attempting to refresh access token...');

    try {
      final profileController = Get.find<ProfileController>();
      final refreshToken = profileController.refreshToken.value;

      if (refreshToken.isEmpty) {
        _log('No refresh token available');
        _isRefreshing = false;
        return false;
      }

      // Call refresh endpoint
      final response = await http.post(
        Uri.parse(
            '${profileController.userRole.value == 'admin' ? 'http://localhost:8000/api/v1/auth' : 'http://localhost:8000/api/v1/auth'}/token/refresh'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newAccessToken = data['access_token'];

        if (newAccessToken != null && newAccessToken.toString().isNotEmpty) {
          // Update token in ProfileController
          profileController.token.value = newAccessToken.toString();
          await profileController.updateProfile(
            avatar: profileController.avatarPath.value,
            name: profileController.userName.value,
            role: profileController.userRole.value,
            email: profileController.userEmail.value,
            first: profileController.firstName.value,
            last: profileController.lastName.value,
            id: profileController.userId.value,
            accessToken: newAccessToken.toString(),
            refreshTokenValue: refreshToken,
          );

          _log('Access token refreshed successfully');
          _isRefreshing = false;

          // Process queued requests
          for (var callback in _refreshQueue) {
            callback();
          }
          _refreshQueue.clear();

          return true;
        }
      }

      _log('Token refresh failed: ${response.statusCode}');
      _isRefreshing = false;
      return false;
    } catch (e) {
      _log('Token refresh error: $e');
      _isRefreshing = false;
      return false;
    }
  }

  static Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _log('Connectivity check result: $result');

      if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        _log('No network connection detected');
        throw NoNetworkException();
      }
    } catch (e) {
      _log('Connectivity check error: $e');
      // Don't throw on connectivity check errors in web
      // The actual request will fail if there's no connection
    }
  }

  static Future<T> _withConnection<T>(Future<T> Function() operation) async {
    await _checkConnectivity();
    return await operation();
  }

  static Future<T> fetchObject<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      _withConnection(() async {
        _log('GET $endpoint');
        final response =
            await http.get(_buildUri(endpoint), headers: defaultHeaders);

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying GET $endpoint with new token');
            final retryResponse =
                await http.get(_buildUri(endpoint), headers: defaultHeaders);

            if (retryResponse.statusCode == 200) {
              final data = json.decode(utf8.decode(retryResponse.bodyBytes));
              return fromJson(data);
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          return fromJson(data);
        } else {
          throw Exception('GET $endpoint failed: ${response.statusCode}');
        }
      });

  static Future<List<T>> fetchList<T>(
    String endpoint,
    T Function(Map<String, dynamic>)
        fromJson, // fromJson build in function to converts each item form the json after parsing it
  ) =>
      // check connection first
      _withConnection(() async {
        // log request if debug mode
        _log('GET $endpoint');
        final response =
            // parse it to json using Uri build in class
            await http.get(_buildUri(endpoint), headers: defaultHeaders);

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying GET $endpoint with new token');
            final retryResponse =
                await http.get(_buildUri(endpoint), headers: defaultHeaders);

            if (retryResponse.statusCode == 200) {
              final data = json.decode(utf8.decode(retryResponse.bodyBytes));
              if (data is List) {
                return data.map((item) => fromJson(item)).toList();
              } else if (data is Map<String, dynamic>) {
                if (data['data'] is List) {
                  return (data['data'] as List)
                      .map((item) => fromJson(item))
                      .toList();
                }
                for (final value in data.values) {
                  if (value is List) {
                    return (value as List)
                        .map((item) => fromJson(item))
                        .toList();
                  }
                }
              }
              throw Exception('Expected a list but got: $data');
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is List) {
            return data.map((item) => fromJson(item)).toList();
          } else if (data is Map<String, dynamic>) {
            // Check for common wrapper keys
            if (data['data'] is List) {
              return (data['data'] as List)
                  .map((item) => fromJson(item))
                  .toList();
            }
            // Fallback: look for any list in the values (e.g. 'students', 'teachers')
            for (final value in data.values) {
              if (value is List) {
                return (value as List).map((item) => fromJson(item)).toList();
              }
            }
          }

          throw Exception('Expected a list but got: $data');
        } else {
          throw Exception('GET $endpoint failed: ${response.statusCode}');
        }
      });

  static Future<T> post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      _withConnection(() async {
        _log('POST $endpoint\nBody: $body');
        final response = await http.post(
          _buildUri(endpoint),
          headers: defaultHeaders,
          body: json.encode(body),
        );

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying POST $endpoint with new token');
            final retryResponse = await http.post(
              _buildUri(endpoint),
              headers: defaultHeaders,
              body: json.encode(body),
            );

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 201) {
              final data = json.decode(utf8.decode(retryResponse.bodyBytes));
              return fromJson(data);
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode == 403) {
          throw Exception('Authentication failed: ${response.body}');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          return fromJson(data);
        } else {
          throw Exception(
              'POST $endpoint failed: ${response.statusCode} - ${response.body}');
        }
      });

  static Future<T> put<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      _withConnection(() async {
        _log('PUT $endpoint\nBody: $body');
        final response = await http.put(
          _buildUri(endpoint),
          headers: defaultHeaders,
          body: json.encode(body),
        );

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying PUT $endpoint with new token');
            final retryResponse = await http.put(
              _buildUri(endpoint),
              headers: defaultHeaders,
              body: json.encode(body),
            );

            if (retryResponse.statusCode == 200) {
              final responseBody = utf8.decode(retryResponse.bodyBytes).trim();
              _log('RETRY Response body length: ${responseBody.length}');
              _log(
                  'RETRY Response body: ${responseBody.length > 200 ? responseBody.substring(0, 200) : responseBody}');

              if (responseBody.isEmpty) {
                // Empty response, return empty map
                return fromJson({});
              }
              final data = json.decode(responseBody);
              _log('RETRY Parsed response data: $data');
              return fromJson(data);
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode == 200) {
          final responseBody = utf8.decode(response.bodyBytes).trim();
          _log('Response body length: ${responseBody.length}');
          _log(
              'Response body: ${responseBody.length > 200 ? responseBody.substring(0, 200) : responseBody}');

          if (responseBody.isEmpty) {
            // Empty response, return empty map
            _log('⚠️ Empty response body, returning empty map');
            return fromJson({});
          }
          final data = json.decode(responseBody);
          _log('✅ Parsed response data keys: ${data.keys}');
          return fromJson(data);
        } else {
          throw Exception(
              'PUT $endpoint failed: ${response.statusCode} - ${response.body}');
        }
      });

  static Future<T> patch<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      _withConnection(() async {
        _log('PATCH $endpoint\nBody: $body');
        final response = await http.patch(
          _buildUri(endpoint),
          headers: defaultHeaders,
          body: json.encode(body),
        );

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying PATCH $endpoint with new token');
            final retryResponse = await http.patch(
              _buildUri(endpoint),
              headers: defaultHeaders,
              body: json.encode(body),
            );

            if (retryResponse.statusCode == 200) {
              final responseBody = utf8.decode(retryResponse.bodyBytes).trim();
              if (responseBody.isEmpty) {
                // Empty response, return empty map
                return fromJson({});
              }
              final data = json.decode(responseBody);
              return fromJson(data);
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode == 200) {
          final responseBody = utf8.decode(response.bodyBytes).trim();
          if (responseBody.isEmpty) {
            // Empty response, return empty map
            _log('Empty response body, returning empty map');
            return fromJson({});
          }
          final data = json.decode(responseBody);
          return fromJson(data);
        } else {
          throw Exception('PATCH $endpoint failed: ${response.statusCode}');
        }
      });

  static Future<void> delete(String endpoint) => _withConnection(() async {
        _log('DELETE $endpoint');
        final response =
            await http.delete(_buildUri(endpoint), headers: defaultHeaders);

        _log(
            'Response (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry request with new token
            _log('Retrying DELETE $endpoint with new token');
            final retryResponse =
                await http.delete(_buildUri(endpoint), headers: defaultHeaders);

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 204) {
              return;
            }
          }

          // Refresh failed, redirect to login
          _log('Token refresh failed, redirecting to login');
          Get.offAllNamed('/login');
          throw Exception('Authentication failed: Session expired');
        }

        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('DELETE $endpoint failed: ${response.statusCode}');
        }
      });
}
