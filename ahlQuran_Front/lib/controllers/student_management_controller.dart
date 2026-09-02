import 'dart:developer' as dev;
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/lecture.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';

/// Controller for Student Management following GetX architecture
class StudentManagementController extends GetxController {
  // Observable lists
  final RxList<Student> allStudents = <Student>[].obs;
  final RxList<Student> filteredStudents = <Student>[].obs;
  final RxList<Lecture> lectures = <Lecture>[].obs;

  // Loading and error states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final Rxn<Lecture> selectedLecture = Rxn<Lecture>();

  // Selection for delete
  final RxList<Student> selectedStudents = <Student>[].obs;
  
  // User role check
  final RxBool isTeacher = false.obs;
  final RxBool isReadOnly = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Check user role
    final profileController = Get.find<ProfileController>();
    final userRole = profileController.userRole.value.toLowerCase();
    isTeacher.value = userRole == 'teacher';
    isReadOnly.value = isTeacher.value; // Teachers have read-only access

    // Ensure selected lecture starts as null
    selectedLecture.value = null;

    // Update drawer selection to "Students" (index 4)
    try {
      if (Get.isRegistered<drawer.DrawerController>()) {
        Get.find<drawer.DrawerController>().changeSelectedIndex(4);
      }
    } catch (e) {
      dev.log('DrawerController not found or error updating index: $e');
    }

    loadInitialData();

    // Listen to search query changes
    debounce(searchQuery, (_) => filterStudents(),
        time: const Duration(milliseconds: 500));

    // Listen to lecture filter changes
    ever(selectedLecture, (_) => filterStudents());
  }

  /// Load all initial data (students and lectures)
  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        fetchAllStudents(),
        fetchAllLectures(),
      ]);
    } catch (e) {
      errorMessage.value = 'فشل تحميل البيانات: ${e.toString()}';
      dev.log('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all students with complete data
  Future<void> fetchAllStudents() async {
    try {
      // Use different endpoint based on user role
      final endpoint = isTeacher.value 
          ? ApiEndpoints.getMyStudents 
          : ApiEndpoints.getStudents;
      
      final students = await ApiService.fetchList<Student>(
        endpoint,
        Student.fromJson,
      );

      allStudents.value = students;
      filteredStudents.value = students;

      dev.log('Fetched ${students.length} students (isTeacher: ${isTeacher.value})');
    } catch (e) {
      errorMessage.value = 'فشل تحميل قائمة الطلاب';
      dev.log('Error fetching students: $e');
      rethrow;
    }
  }

  /// Fetch all lectures (حلقات)
  Future<void> fetchAllLectures() async {
    try {
      if (isTeacher.value) {
        // Teachers get their own lectures - direct list response
        final lectureList = await ApiService.fetchList<Lecture>(
          ApiEndpoints.getMyLectures,
          Lecture.fromJson,
        );
        
        lectures.value = lectureList;
        
        // Clear selected lecture if it doesn't exist in the new list
        if (selectedLecture.value != null) {
          final exists = lectureList.any((l) => l.lectureId == selectedLecture.value!.lectureId);
          if (!exists) {
            selectedLecture.value = null;
          }
        }
        
        dev.log('Fetched ${lectureList.length} lectures for teacher');
      } else {
        // Others get all lectures - standard list response
        final lectureList = await ApiService.fetchList<Lecture>(
          ApiEndpoints.getLectures,
          Lecture.fromJson,
        );
        
        lectures.value = lectureList;
        
        // Clear selected lecture if it doesn't exist in the new list
        if (selectedLecture.value != null) {
          final exists = lectureList.any((l) => l.lectureId == selectedLecture.value!.lectureId);
          if (!exists) {
            selectedLecture.value = null;
          }
        }
        
        dev.log('Fetched ${lectureList.length} lectures');
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل قائمة الحلقات';
      dev.log('Error fetching lectures: $e');
      rethrow;
    }
  }

  /// Filter students by lecture ID (client-side filtering)
  void filterByLecture(int? lectureId) {
    if (lectureId == null) {
      filteredStudents.value = allStudents;
      return;
    }

    filteredStudents.value = allStudents.where((student) {
      return student.lectures.any((lecture) => lecture.lectureId == lectureId);
    }).toList();

    dev.log(
        'Filtered ${filteredStudents.length} students for lecture $lectureId');
  }

  /// Filter students based on search query and selected lecture
  void filterStudents() {
    List<Student> filtered = allStudents;

    // Filter by lecture if selected
    if (selectedLecture.value != null) {
      final lectureId = selectedLecture.value!.lectureId;
      filtered = filtered.where((student) {
        return student.lectures
            .any((lecture) => lecture.lectureId == lectureId);
      }).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((student) {
        final firstNameAr =
            student.personalInfo.firstNameAr?.toLowerCase() ?? '';
        final lastNameAr = student.personalInfo.lastNameAr?.toLowerCase() ?? '';
        final username = student.accountInfo.username?.toLowerCase() ?? '';

        return firstNameAr.contains(query) ||
            lastNameAr.contains(query) ||
            username.contains(query);
      }).toList();
    }

    filteredStudents.value = filtered;
  }

  /// Add new student
  Future<bool> addStudent(Student student) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await ApiService.post(
        ApiEndpoints.submitStudentForm,
        student.toJson(),
        (json) => Student.fromJson(json),
      );

      await fetchAllStudents();
      dev.log('Student added successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'فشل إضافة الطالب';
      dev.log('Error adding student: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing student
  Future<bool> updateStudent(int studentId, Student student) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await ApiService.put(
        ApiEndpoints.getSpecialStudent(studentId),
        student.toJson(),
        (json) => Student.fromJson(json),
      );

      await fetchAllStudents();
      dev.log('Student updated successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'فشل تحديث الطالب';
      dev.log('Error updating student: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete student by student ID
  Future<bool> deleteStudent(Student student) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Delete using student ID endpoint
      await ApiService.delete(
        ApiEndpoints.getStudentById(student.personalInfo.studentId as int),
      );

      // Remove from lists
      allStudents.remove(student);
      filteredStudents.remove(student);
      selectedStudents.remove(student);

      dev.log('Student deleted successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'فشل حذف الطالب';
      dev.log('Error deleting student: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete multiple selected students
  Future<bool> deleteSelectedStudents() async {
    if (selectedStudents.isEmpty) {
      errorMessage.value = 'لم يتم تحديد أي طالب للحذف';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    bool allSuccess = true;

    try {
      for (var student in selectedStudents.toList()) {
        try {
          await ApiService.delete(
            ApiEndpoints.getStudentById(student.personalInfo.studentId as int),
          );
        } catch (e) {
          allSuccess = false;
          dev.log(
              'Failed to delete student ${student.personalInfo.studentId}: $e');
        }
      }

      // Refresh the list
      await fetchAllStudents();
      selectedStudents.clear();

      return allSuccess;
    } catch (e) {
      errorMessage.value = 'فشل حذف الطلاب المحددين';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle student selection
  void toggleStudentSelection(Student student) {
    if (selectedStudents.contains(student)) {
      selectedStudents.remove(student);
    } else {
      selectedStudents.add(student);
    }
  }

  /// Check if student is selected
  bool isStudentSelected(Student student) {
    return selectedStudents.contains(student);
  }

  /// Clear all selections
  void clearSelections() {
    selectedStudents.clear();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Update lecture filter
  void updateLectureFilter(Lecture? lecture) {
    selectedLecture.value = lecture;
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedLecture.value = null;
    filteredStudents.value = allStudents;
  }

  /// Refresh all data
  @override
  Future<void> refresh() async {
    await loadInitialData();
  }
}
