import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';

class GenericController<T extends Model> extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<T> listOfModels = <T>[].obs;
  final RxString errorMessage = ''.obs;

  final T Function(Map<String, dynamic>) fromJson;

  GenericController({required this.fromJson});

  /// Fetches exam notes data from the API
  Future<void> fetchlistOfModels(String url, {VoidCallback? onFinished}) async {
    try {
      errorMessage.value = '';
      final result = await ApiService.fetchList<T>(
        url,
        fromJson,
      );

      if (result.isEmpty) {
        errorMessage.value = 'لم يتم العثور على بيانات';
        listOfModels.clear();
      } else {
        listOfModels.value = result;
      }
    } catch (e) {
      errorMessage.value =
          'فشل الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.';
      listOfModels.clear();
    } finally {
      onFinished?.call();
    }
  }

  /// Deletes an exam note by ID
  Future<void> deleteData(String endpoint) async {
    try {
      await ApiService.delete(endpoint);
      dev.log('تم حذف بنجاح');
    } catch (e) {
      errorMessage.value = 'فشل الحذف';
      dev.log('فشل الحذف');
    }
  }

  Future<void> postDelete(String endpoint, int id) async {
    await ApiService.delete('$endpoint/$id');
    await fetchlistOfModels(endpoint); // Refresh list
  }
}
