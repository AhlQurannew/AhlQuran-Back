import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../helpers/date_picker.dart';
import '../utils/snackbar_helper.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class TeacherAttendanceSelectionScreen extends StatefulWidget {
  const TeacherAttendanceSelectionScreen({super.key});

  @override
  State<TeacherAttendanceSelectionScreen> createState() =>
      _TeacherAttendanceSelectionScreenState();
}

class _TeacherAttendanceSelectionScreenState
    extends State<TeacherAttendanceSelectionScreen> {
  final TextEditingController dateController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Set today's date as default
    final today = DateTime.now();
    dateController.text =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(10);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "متابعة مواظبة المعلمين",
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
            'متابعة مواظبة المعلمين / الصفحة الرئيسية',
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

  Widget _buildDatePicker(ThemeData theme) {
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
        if (dateController.text.isEmpty) {
          showInfoSnackbar('الرجاء اختيار التاريخ', context: context);
          return;
        }

        // Navigate to teachers list screen
        Get.toNamed(
          '/teacher-attendance/list?date=${Uri.encodeComponent(dateController.text)}',
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
        'رجاء قم باختيار التاريخ',
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
