import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../../new_models/attendance.dart';
import '../../new_models/student.dart';
import '../../services/api_client.dart';
import '../../services/network/api_endpoints.dart';
import '../../utils/snackbar_helper.dart';
import '../../../controllers/profile_controller.dart';

class AttendanceDialog extends StatefulWidget {
  final Student student;
  final String date;

  const AttendanceDialog({
    super.key,
    required this.student,
    required this.date,
  });

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  Attendance? currentAttendance;
  bool isLoading = true;
  String? selectedStatus;
  final TextEditingController notesController = TextEditingController();
  bool isTeacher = false;

  final List<Map<String, dynamic>> statusOptions = [
    {'value': 'present', 'label': 'حاضر', 'color': Color(0xFF4CAF50)},
    {'value': 'late', 'label': 'متأخر', 'color': Color(0xFFFFA726)},
    {'value': 'absent', 'label': 'غائب', 'color': Color(0xFFEF5350)},
    {'value': 'excused', 'label': 'غائب بعذر', 'color': Color(0xFF42A5F5)},
  ];

  @override
  void initState() {
    super.initState();
    
    // Check if user is a teacher
    try {
      final profileController = Get.find<ProfileController>();
      isTeacher = profileController.userRole.value.toLowerCase() == 'teacher';
      dev.log('User is teacher: $isTeacher');
    } catch (e) {
      dev.log('Error checking user role: $e');
      isTeacher = false;
    }
    
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      if (widget.student.id == null) {
        throw Exception('Student ID is null');
      }

      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? '${ApiEndpoints.getMyStudentAttendance(widget.student.id!)}?date=${widget.date}'
          : '${ApiEndpoints.getStudents}${widget.student.id}/attendance?date=${widget.date}';
      
      dev.log('Loading attendance from: $endpoint');

      // Load attendance for this student and date
      final attendances = await ApiService.fetchList(
        endpoint,
        Attendance.fromJson,
      );

      setState(() {
        if (attendances.isNotEmpty) {
          currentAttendance = attendances.first;
          selectedStatus = currentAttendance!.status;
          notesController.text = currentAttendance!.notes ?? '';
        }
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading attendance: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedStatus == null) {
      showErrorSnackbar('الرجاء اختيار حالة المواظبة', context: context);
      return;
    }

    try {
      final attendanceData = Attendance(
        studentId: widget.student.id!,
        date: widget.date,
        status: selectedStatus!,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      // Use teacher-specific endpoint if user is a teacher
      final endpoint = isTeacher
          ? ApiEndpoints.createMyStudentAttendance(widget.student.id!)
          : '${ApiEndpoints.getStudents}${widget.student.id}/attendance';
      
      dev.log('Saving attendance to: $endpoint');

      // Save to backend
      final savedAttendance = await ApiService.post(
        endpoint,
        attendanceData.toJson(),
        Attendance.fromJson,
      );

      if (mounted) {
        showSuccessSnackbar('تم حفظ المواظبة بنجاح', context: context);
        // Return the saved attendance object
        Navigator.pop(context, savedAttendance);
      }
    } catch (e) {
      dev.log('Error saving attendance: $e');
      if (mounted) {
        showErrorSnackbar('فشل في حفظ المواظبة', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentName =
        '${widget.student.personalInfo.firstNameAr ?? ''} ${widget.student.personalInfo.lastNameAr ?? ''}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(studentName),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Selection
                        _buildStatusSection(),

                        const SizedBox(height: 24),

                        // Notes Section
                        _buildNotesSection(),

                        const SizedBox(height: 24),

                        // Save Button
                        _buildSaveButton(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4DB6AC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'بيانات المواظبة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'المواظبة :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4DB6AC).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: statusOptions.map((option) {
              final isSelected = selectedStatus == option['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedStatus = option['value'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option['color'].withValues(alpha: 0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected ? option['color'] : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: option['color'],
                            size: 20,
                          ),
                        if (isSelected) const SizedBox(width: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                isSelected ? option['color'] : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'ملاحظة الأستاذ :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 3,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'جيد',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveAttendance,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'حفظ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
