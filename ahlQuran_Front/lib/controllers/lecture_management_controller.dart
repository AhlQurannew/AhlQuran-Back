import 'dart:developer' as dev;
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/lecture_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';

/// Controller for Lecture Management following GetX architecture
class LectureManagementController extends GetxController {
  // Observable lists
  final RxList<LectureForm> allLectures = <LectureForm>[].obs;
  final RxList<LectureForm> filteredLectures = <LectureForm>[].obs;
  final RxList<Teacher> teachers = <Teacher>[].obs;

  // Loading and error states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final Rxn<Teacher> selectedTeacher = Rxn<Teacher>();

  // Selection for delete
  final RxList<LectureForm> selectedLectures = <LectureForm>[].obs;

  bool get _isTeacher {
    try {
      final profileController = Get.find<ProfileController>();
      return profileController.userRole.value == 'teacher';
    } catch (e) {
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Update drawer selection to "Lectures" (index 3)
    try {
      if (Get.isRegistered<drawer.DrawerController>()) {
        Get.find<drawer.DrawerController>().changeSelectedIndex(3);
      }
    } catch (e) {
      dev.log('DrawerController not found or error updating index: $e');
    }

    loadInitialData();

    // Listen to search query changes
    debounce(searchQuery, (_) => filterLectures(),
        time: const Duration(milliseconds: 500));

    // Listen to teacher filter changes
    ever(selectedTeacher, (_) => filterLectures());
  }

  /// Load all initial data (lectures and teachers)
  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Always fetch lectures first
      await fetchAllLectures();
      
      // Only fetch teachers if not a teacher (admins/supervisors need this)
      if (!_isTeacher) {
        await fetchAllTeachers();
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل البيانات: ${e.toString()}';
      dev.log('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all lectures with complete data
  Future<void> fetchAllLectures() async {
    try {
      final endpoint = _isTeacher 
          ? ApiEndpoints.getMyLectures 
          : ApiEndpoints.getSpecialLectures;
      
      dev.log('Fetching lectures from endpoint: $endpoint (isTeacher: $_isTeacher)');
      
      final lectures = await ApiService.fetchList<LectureForm>(
        endpoint,
        LectureForm.fromJson,
      );

      allLectures.value = lectures;
      filteredLectures.value = lectures;

      dev.log('Fetched ${lectures.length} lectures');
      
      // Debug: Log student counts
      for (var lecture in lectures) {
        dev.log('Lecture: ${lecture.lecture.lectureNameAr}, Student Count: ${lecture.studentCount}');
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل قائمة الحلقات';
      dev.log('Error fetching lectures: $e');
      rethrow;
    }
  }

  /// Fetch all teachers
  Future<void> fetchAllTeachers() async {
    try {
      final teacherList = await ApiService.fetchList<Teacher>(
        ApiEndpoints.getTeachers,
        Teacher.fromJson,
      );

      teachers.value = teacherList;
      dev.log('Fetched ${teacherList.length} teachers');
    } catch (e) {
      errorMessage.value = 'فشل تحميل قائمة المعلمين';
      dev.log('Error fetching teachers: $e');
      // Don't rethrow - teachers are optional
    }
  }

  /// Filter lectures based on search query and teacher filter
  void filterLectures() {
    var result = allLectures.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((lecture) {
        return lecture.lecture.lectureNameAr.toLowerCase().contains(query) ||
            lecture.lecture.lectureNameEn.toLowerCase().contains(query);
      }).toList();
    }

    // Apply teacher filter
    if (selectedTeacher.value != null) {
      result = result.where((lecture) {
        return lecture.teachers
            .any((t) => t.teacherId == selectedTeacher.value!.teacherId);
      }).toList();
    }

    filteredLectures.value = result;
    dev.log('Filtered lectures: ${result.length}');
  }

  /// Toggle lecture selection for batch operations
  void toggleLectureSelection(LectureForm lecture) {
    if (selectedLectures.contains(lecture)) {
      selectedLectures.remove(lecture);
    } else {
      selectedLectures.add(lecture);
    }
  }

  /// Check if lecture is selected
  bool isLectureSelected(LectureForm lecture) {
    return selectedLectures.contains(lecture);
  }

  /// Select all filtered lectures
  void selectAllLectures() {
    selectedLectures.clear();
    selectedLectures.addAll(filteredLectures);
  }

  /// Deselect all lectures
  void deselectAllLectures() {
    selectedLectures.clear();
  }

  /// Update an existing lecture
  Future<void> updateLecture(int lectureId, LectureForm lectureForm) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Send PUT request with the same structure as POST
      final response = await ApiService.put(
        ApiEndpoints.updateLecture(lectureId),
        lectureForm.toJson(),
        LectureForm.fromJson,
      );

      dev.log('Lecture updated successfully: $response');

      // Refresh the list to get updated data
      await fetchAllLectures();

      Get.snackbar('نجح', 'تم تحديث الحلقة بنجاح');
    } catch (e) {
      errorMessage.value = 'فشل تحديث الحلقة';
      dev.log('Error updating lecture: $e');
      Get.snackbar('خطأ', 'فشل تحديث الحلقة: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a single lecture
  Future<void> deleteLecture(int lectureId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await ApiService.delete(
        ApiEndpoints.deleteLecture(lectureId),
      );

      dev.log('Lecture deleted successfully: $lectureId');

      // Refresh the list
      await fetchAllLectures();

      Get.snackbar('نجح', 'تم حذف الحلقة بنجاح');
    } catch (e) {
      errorMessage.value = 'فشل حذف الحلقة';
      dev.log('Error deleting lecture: $e');
      Get.snackbar('خطأ', 'فشل حذف الحلقة: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete selected lectures
  Future<void> deleteSelectedLectures() async {
    if (selectedLectures.isEmpty) {
      Get.snackbar('تنبيه', 'الرجاء تحديد حلقات للحذف');
      return;
    }

    try {
      isLoading.value = true;

      for (var lecture in selectedLectures) {
        final lectureId = lecture.lecture.lectureId;
        if (lectureId != null) {
          await ApiService.delete(
            ApiEndpoints.deleteLecture(lectureId),
          );
        }
      }

      // Refresh the list
      await fetchAllLectures();
      selectedLectures.clear();

      Get.snackbar('نجح', 'تم حذف الحلقات بنجاح');
    } catch (e) {
      errorMessage.value = 'فشل حذف الحلقات';
      dev.log('Error deleting lectures: $e');
      Get.snackbar('خطأ', 'فشل حذف الحلقات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Duplicate selected lecture
  Future<void> duplicateLecture(LectureForm lecture) async {
    try {
      // Create a copy with cleared IDs
      final newLecture = LectureForm(
        lecture: lecture.lecture,
        teachers: lecture.teachers,
        schedules: lecture.schedules,
        studentCount: 0,
      );

      // Clear IDs for duplication
      newLecture.lecture.lectureId = null;
      for (var schedule in newLecture.schedules) {
        schedule.weeklyScheduleId = null;
      }

      // The dialog will handle the actual creation
      // Just return the duplicated data
      Get.snackbar('معلومة', 'تم نسخ البيانات. يرجى تعديلها وحفظها.');

      // TODO: Open dialog with duplicated data
    } catch (e) {
      dev.log('Error duplicating lecture: $e');
      Get.snackbar('خطأ', 'فشل نسخ الحلقة');
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadInitialData();
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
