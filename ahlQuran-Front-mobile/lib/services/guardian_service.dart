import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/achievement.dart';
import 'api_config.dart';
import 'auth_service.dart';

class GuardianService {
  final AuthService _authService = AuthService();

  Future<StudentListResponse> getMyChildren() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConfig.guardianBaseUrl}/my-children');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StudentListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('No children found.');
      } else {
        throw Exception('Failed to load children.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  Future<Student> getChildDetail(int studentId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse(
      '${ApiConfig.guardianBaseUrl}/my-children/$studentId',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have access to this child.');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found.');
      } else {
        throw Exception('Failed to load child details.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  Future<PaginatedAttendanceResponse> getStudentAttendance({
    required int studentId,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }

    final url = Uri.parse(
      '${ApiConfig.guardianBaseUrl}/students/$studentId/attendance',
    ).replace(queryParameters: queryParams);

    print('Fetching attendance from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaginatedAttendanceResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have access to this student.');
      } else if (response.statusCode == 404) {
        throw Exception('Student not found.');
      } else {
        throw Exception('Failed to load attendance records.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  Future<PaginatedAchievementsResponse> getStudentAchievements({
    required int studentId,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }

    final url = Uri.parse(
      '${ApiConfig.guardianBaseUrl}/students/$studentId/achievements',
    ).replace(queryParameters: queryParams);

    print('Fetching achievements from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaginatedAchievementsResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have access to this student.');
      } else if (response.statusCode == 404) {
        throw Exception('Student not found.');
      } else {
        throw Exception('Failed to load achievements.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}
