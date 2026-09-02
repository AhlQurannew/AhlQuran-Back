import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/acheivement_class.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import '/system/services/network/api_endpoints.dart';
import 'package:flutter/material.dart';

class AchievementController extends GetxController {
  RxnInt lectureId = RxnInt();
  RxString date = ''.obs;
  RxList<Acheivement> achievementList = <Acheivement>[].obs;
  RxBool isLoading = true.obs;
  RxBool isrequestCompleted = false.obs;
  RxString errorMessage = ''.obs;

  void setLectureId(int? id) {
    if (id == null) return;
    lectureId.value = id;
    fetchData();
  }

  void setDate(String newDate) {
    date.value = newDate;
  }

  Future<void> fetchData({VoidCallback? onFinished}) async {
    errorMessage.value = '';

    try {
      final result = await ApiService.fetchList<Acheivement>(
          ApiEndpoints.getLectureById(lectureId.value ?? 0), //TODO handle null
          (json) => Acheivement.fromJson(json));

      if (result.isNotEmpty) {
        isrequestCompleted.value = true;
        achievementList.value = result;
      } else {
        isrequestCompleted.value = true;
        errorMessage.value = 'Unknown error fetching students';
      }
    } catch (e) {
      isrequestCompleted.value = true;
      errorMessage.value =
          'Failed to connect to server. Please check your connection.';
    } finally {
      onFinished?.call();
    }
  }
}
