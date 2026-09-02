import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../system/services/network/api_endpoints.dart';
import '../routes/app_routes.dart';

class PendingPresident {
  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String? schoolName;
  final String? phoneNumber;

  PendingPresident({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.schoolName,
    this.phoneNumber,
  });

  factory PendingPresident.fromJson(Map<String, dynamic> json) {
    return PendingPresident(
      id: json['id'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      schoolName: json['school_name'],
      phoneNumber: json['phone_number'],
    );
  }
}

class AdminController extends GetxController {
  final RxList<PendingPresident> pendingPresidents = <PendingPresident>[].obs;
  final RxBool isLoading = false.obs;
  final RxString adminToken = ''.obs;

  Future<void> fetchPendingPresidents() async {
    if (adminToken.value.isEmpty) {
      print('No admin token available');
      return;
    }

    try {
      isLoading.value = true;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/pending-presidents');

      print('Fetching pending presidents from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${adminToken.value}',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List presidents = data['pending_presidents'] ?? [];

        pendingPresidents.value =
            presidents.map((json) => PendingPresident.fromJson(json)).toList();

        print('Loaded ${pendingPresidents.length} pending presidents');
      } else {
        Get.snackbar(
          'خطأ',
          'فشل تحميل الطلبات المعلقة',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      print('Error fetching pending presidents: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل البيانات',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approvePresident(int userId) async {
    if (adminToken.value.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يجب تسجيل الدخول كمسؤول',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      final url =
          Uri.parse('${ApiEndpoints.baseUrl}/admin/approve-president/$userId');

      print('Approving president: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${adminToken.value}',
          'Content-Type': 'application/json',
        },
      );

      print('Approve response status: ${response.statusCode}');
      print('Approve response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        Get.snackbar(
          'نجح',
          data['message'] ?? 'تم قبول الطلب بنجاح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        // Remove the approved president from the list
        pendingPresidents.removeWhere((p) => p.id == userId);
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        Get.snackbar(
          'خطأ',
          errorData['detail'] ?? 'فشل قبول الطلب',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      print('Error approving president: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء قبول الطلب',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  void setAdminToken(String token) {
    adminToken.value = token;
    fetchPendingPresidents();
  }

  Future<void> logout() async {
    try {
      // Clear token and data
      adminToken.value = '';
      pendingPresidents.clear();

      // Navigate to login page (no snackbar needed as user is leaving the page)
      Get.offAllNamed(Routes.logIn);
    } catch (e) {
      print('Logout error: $e');
    }
  }
}
