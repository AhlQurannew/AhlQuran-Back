import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../../helpers/date_picker.dart';
import '../new_models/lecture.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../utils/snackbar_helper.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class LectureDetailReportSelectionScreen extends StatefulWidget {
  const LectureDetailReportSelectionScreen({super.key});

  @override
  State<LectureDetailReportSelectionScreen> createState() =>
      _LectureDetailReportSelectionScreenState();
}

class _LectureDetailReportSelectionScreenState
    extends State<LectureDetailReportSelectionScreen> {
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  Lecture? selectedLecture;
  List<Lecture> lectures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Set default dates (last 7 days)
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    startDateController.text =
        "${sevenDaysAgo.day.toString().padLeft(2, '0')}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.year}";
    endDateController.text =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

    _loadLectures();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(11);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  Future<void> _loadLectures() async {
    try {
      final response = await ApiService.fetchList(
        ApiEndpoints.getLectures,
        Lecture.fromJson,
      );

      setState(() {
        lectures = response;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading lectures: $e');
      setState(() {
        lectures = [];
        isLoading = false;
      });
      showErrorSnackbar('فشل في تحميل الحلقات', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "التقرير التفصيلي للحلقات",
        child: Column(
          children: [
            _buildHeaderBar(theme),
            const SizedBox(height: 24),
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
                            _buildLectureDropdown(theme),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildDatePicker(theme, true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDatePicker(theme, false)),
                              ],
                            ),
                            const SizedBox(height: 32),
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
            'التقرير التفصيلي للحلقات',
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
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

  Widget _buildDatePicker(ThemeData theme, bool isStartDate) {
    final controller = isStartDate ? startDateController : endDateController;
    final label = isStartDate ? 'تاريخ البداية' : 'تاريخ النهاية';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF4DB6AC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              DateTime initialDate;
              if (controller.text.isNotEmpty) {
                try {
                  final parts = controller.text.split('-');
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
                  controller.text =
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
                    controller.text,
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
        if (startDateController.text.isEmpty ||
            endDateController.text.isEmpty) {
          showInfoSnackbar('الرجاء اختيار التواريخ', context: context);
          return;
        }

        Get.toNamed(
          '/lecture-detail-report?lectureId=${selectedLecture!.lectureId}&lectureName=${Uri.encodeComponent(selectedLecture!.lectureNameAr ?? '')}&startDate=${Uri.encodeComponent(startDateController.text)}&endDate=${Uri.encodeComponent(endDateController.text)}',
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
        'عرض التقرير',
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
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}
