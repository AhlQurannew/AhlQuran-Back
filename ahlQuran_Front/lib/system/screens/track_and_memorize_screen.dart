import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../../helpers/date_picker.dart';
import '../new_models/lecture.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../utils/snackbar_helper.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import 'base_layout.dart';

class TrackAndMemorizeScreen extends StatefulWidget {
  const TrackAndMemorizeScreen({super.key});

  @override
  State<TrackAndMemorizeScreen> createState() => _TrackAndMemorizeScreenState();
}

class _TrackAndMemorizeScreenState extends State<TrackAndMemorizeScreen> {
  final TextEditingController dateController = TextEditingController();
  Lecture? selectedLecture;
  List<Lecture> lectures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Set today's date as default
    final today = DateTime.now();
    dateController.text =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

    _loadLectures();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(8);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  Future<void> _loadLectures() async {
    try {
      // Check if user is a teacher
      bool isTeacher = false;
      try {
        final profileController = Get.find<ProfileController>();
        isTeacher = profileController.userRole.value.toLowerCase() == 'teacher';
        dev.log('User is teacher: $isTeacher');
      } catch (e) {
        dev.log('Error checking user role: $e');
      }

      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? ApiEndpoints.getMyLectures
          : ApiEndpoints.getLectures;
      
      dev.log('Loading lectures from: $endpoint');

      final response = await ApiService.fetchList(
        endpoint,
        Lecture.fromJson,
      );

      setState(() {
        lectures = response;
        isLoading = false;
      });
      
      dev.log('Successfully loaded ${lectures.length} lectures');
    } catch (e) {
      dev.log('Error loading lectures: $e');
      setState(() {
        lectures = [];
        isLoading = false;
      });
      
      // Check if it's an authentication error
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        showErrorSnackbar('انتهت صلاحية الجلسة. الرجاء تسجيل الدخول مرة أخرى', context: context);
      } else {
        showErrorSnackbar('فشل في تحميل الحلقات: ${e.toString()}', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "متابعة الحفظ والمراجعة",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 24),

            // Selection form
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Lecture Selection
                            _buildLectureDropdown(theme),

                            const SizedBox(height: 24),

                            // Date Selection
                            _buildDatePicker(theme),

                            const SizedBox(height: 32),

                            // Submit Button
                            _buildSubmitButton(),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDEB059),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'متابعة الحفظ والمراجعة / الصفحة الرئيسية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Color(0xFF4DB6AC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'الحلقة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'اختر الحلقة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Lecture>(
                isExpanded: true,
                value: selectedLecture,
                hint: const Text('البحث عن الحلقات'),
                items: lectures.map((lecture) {
                  return DropdownMenuItem<Lecture>(
                    value: lecture,
                    child: Text(lecture.lectureNameAr ?? ''),
                  );
                }).toList(),
                onChanged: (Lecture? value) {
                  setState(() {
                    selectedLecture = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DB6AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF4DB6AC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'التاريخ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'اختر التاريخ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              DateTime initialDate;
              if (dateController.text.isNotEmpty) {
                try {
                  final parts = dateController.text.split('-');
                  initialDate = DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[1]),
                    int.parse(parts[0]),
                  );
                } catch (e) {
                  initialDate = DateTime.now();
                }
              } else {
                initialDate = DateTime.now();
              }

              final pickedDate = await showCustomDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                setState(() {
                  dateController.text =
                      "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateController.text,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (selectedLecture == null) {
          showInfoSnackbar('الرجاء اختيار الحلقة', context: context);
          return;
        }
        if (dateController.text.isEmpty) {
          showInfoSnackbar('الرجاء اختيار التاريخ', context: context);
          return;
        }

        // Navigate to students list screen with query parameters for persistence
        Get.toNamed(
          '${Routes.trackAndMemorizeStudents}?lectureId=${selectedLecture!.lectureId}&lectureName=${Uri.encodeComponent(selectedLecture!.lectureNameAr ?? '')}&date=${Uri.encodeComponent(dateController.text)}',
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DB6AC),
        padding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'رجاء قم باختيار التاريخ والحلقة',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }
}
