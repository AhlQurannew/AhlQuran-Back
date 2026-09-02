import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../new_models/lecture.dart';
import '../new_models/student.dart';
import '../new_models/attendance.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import '../../controllers/profile_controller.dart';
import 'base_layout.dart';

class AttendanceStudentsScreen extends StatefulWidget {
  const AttendanceStudentsScreen({super.key});

  @override
  State<AttendanceStudentsScreen> createState() =>
      _AttendanceStudentsScreenState();
}

class _AttendanceStudentsScreenState extends State<AttendanceStudentsScreen> {
  Lecture? lecture;
  String? date;
  List<Student> students = [];
  Map<int, Attendance?> attendanceRecords = {};
  bool isLoading = true;
  bool isTeacher = false;

  final List<Map<String, dynamic>> statusOptions = [
    {'value': 'present', 'label': 'حضور', 'color': Color(0xFF4CAF50)},
    {'value': 'late', 'label': 'تأخر', 'color': Color(0xFFFFA726)},
    {'value': 'absent', 'label': 'غياب', 'color': Color(0xFFEF5350)},
    {'value': 'excused', 'label': 'عذر', 'color': Color(0xFF42A5F5)},
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

    // Try to get from arguments first (for navigation)
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      lecture = args['lecture'] as Lecture?;
      date = args['date'] as String?;
    } else {
      // Fallback to query parameters (for page reload)
      final parameters = Get.parameters;
      final lectureId = parameters['lectureId'];
      final lectureName = parameters['lectureName'];
      date = parameters['date'];

      if (lectureId != null && lectureName != null) {
        lecture = Lecture(
          lectureId: int.tryParse(lectureId),
          lectureNameAr: lectureName,
        );
      }
    }

    dev.log('Lecture: ${lecture?.lectureNameAr}, Date: $date');

    _loadStudents();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(9);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  Future<void> _loadStudents() async {
    try {
      // Only load students if we have a lecture selected
      if (lecture?.lectureId == null) {
        setState(() {
          students = [];
          isLoading = false;
        });
        return;
      }

      // Fetch students filtered by the selected lecture
      // Use different endpoint based on user role
      final endpoint = isTeacher
          ? '${ApiEndpoints.getMyStudents}?lecture_id=${lecture!.lectureId}'
          : '${ApiEndpoints.getStudents}?lecture_id=${lecture!.lectureId}';

      final response = await ApiService.fetchList(
        endpoint,
        Student.fromJson,
      );

      setState(() {
        students = response;
      });

      // Load attendance records for each student
      await _loadAttendanceRecords();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading students: $e');
      setState(() {
        students = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (date == null) return;

    for (var student in students) {
      if (student.id != null) {
        try {
          // Use teacher-specific endpoint if user is a teacher
          final endpoint = isTeacher
              ? '${ApiEndpoints.getMyStudentAttendance(student.id!)}?date=$date'
              : '${ApiEndpoints.getStudents}${student.id}/attendance?date=$date';

          final attendances = await ApiService.fetchList(
            endpoint,
            Attendance.fromJson,
          );

          if (attendances.isNotEmpty) {
            attendanceRecords[student.id!] = attendances.first;
          } else {
            attendanceRecords[student.id!] = null;
          }
        } catch (e) {
          dev.log('Error loading attendance for student ${student.id}: $e');
          attendanceRecords[student.id!] = null;
        }
      }
    }
  }

  void _showBulkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => _BulkAttendanceDialog(
        students: students,
        date: date ?? '',
        initialAttendanceRecords: Map.from(attendanceRecords),
        statusOptions: statusOptions,
        isTeacher: isTeacher,
      ),
    ).then((result) {
      // Reload attendance records after dialog closes
      if (result == true) {
        _loadAttendanceRecords().then((_) => setState(() {}));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "متابعة المواظبة",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Lecture and Date info
            _buildInfoBar(theme),

            const SizedBox(height: 16),

            // Action button
            _buildActionButton(theme),

            const SizedBox(height: 16),

            // Students table
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStudentsTable(theme),
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
            'متابعة المواظبة / الصفحة الرئيسية',
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

  Widget _buildInfoBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Lecture
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'الحلقة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    lecture?.lectureNameAr ?? '',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Date
          Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'التاريخ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Attendance button
          ElevatedButton.icon(
            onPressed: () {
              _showBulkAttendanceDialog();
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('المواظبة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDEB059),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(ThemeData theme) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد طلاب في هذه الحلقة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4DB6AC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'الطالب',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المواظبة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isEven = index % 2 == 0;
                final attendance = attendanceRecords[student.id];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.grey.shade50 : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Index
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Student name
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Attendance status
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: attendance != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: attendance
                                        .getStatusColor()
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: attendance.getStatusColor(),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    attendance.getStatusArabic(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: attendance.getStatusColor(),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const Text(
                                  '--',
                                  style: TextStyle(fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Bulk Attendance Dialog Widget
class _BulkAttendanceDialog extends StatefulWidget {
  final List<Student> students;
  final String date;
  final Map<int, Attendance?> initialAttendanceRecords;
  final List<Map<String, dynamic>> statusOptions;
  final bool isTeacher;

  const _BulkAttendanceDialog({
    required this.students,
    required this.date,
    required this.initialAttendanceRecords,
    required this.statusOptions,
    required this.isTeacher,
  });

  @override
  State<_BulkAttendanceDialog> createState() => _BulkAttendanceDialogState();
}

class _BulkAttendanceDialogState extends State<_BulkAttendanceDialog> {
  late Map<int, String?> selectedStatuses;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected statuses from existing attendance records
    selectedStatuses = {};
    for (var student in widget.students) {
      if (student.id != null) {
        final attendance = widget.initialAttendanceRecords[student.id];
        selectedStatuses[student.id!] = attendance?.status;
      }
    }
  }

  void _toggleSelectAllForStatus(String status) {
    setState(() {
      // Check if all students already have this status
      bool allHaveStatus = widget.students.every((student) =>
          student.id != null && selectedStatuses[student.id] == status);

      if (allHaveStatus) {
        // Deselect all - clear the status for all students
        for (var student in widget.students) {
          if (student.id != null) {
            selectedStatuses[student.id!] = null;
          }
        }
      } else {
        // Select all - set this status for all students
        for (var student in widget.students) {
          if (student.id != null) {
            selectedStatuses[student.id!] = status;
          }
        }
      }
    });
  }

  Future<void> _saveAllAttendance() async {
    setState(() {
      isSaving = true;
    });

    try {
      dev.log(
          'Starting to save attendance for ${widget.students.length} students');
      dev.log('Selected statuses: $selectedStatuses');
      dev.log('Is teacher: ${widget.isTeacher}');

      int savedCount = 0;
      int deletedCount = 0;

      // Process each student
      for (var student in widget.students) {
        if (student.id == null) continue;

        final currentStatus = selectedStatuses[student.id!];
        final initialAttendance = widget.initialAttendanceRecords[student.id!];

        // Determine the correct endpoint based on user role
        final createEndpoint = widget.isTeacher
            ? ApiEndpoints.createMyStudentAttendance(student.id!)
            : '${ApiEndpoints.getStudents}${student.id}/attendance';

        final deleteEndpoint = widget.isTeacher
            ? ApiEndpoints.deleteMyStudentAttendance(
                student.id!, initialAttendance?.id ?? 0)
            : '${ApiEndpoints.getStudents}${student.id}/attendance/${initialAttendance?.id}';

        // Case 1: Status is null and there was an initial attendance - DELETE
        if (currentStatus == null && initialAttendance != null) {
          dev.log('Deleting attendance for student ${student.id}');

          try {
            await ApiService.delete(deleteEndpoint);
            deletedCount++;
            dev.log(
                'Successfully deleted attendance for student ${student.id}');
          } catch (e) {
            dev.log('Error deleting attendance for student ${student.id}: $e');
            // Continue with other students even if one fails
          }
        }
        // Case 2: Status is not null - SAVE/UPDATE
        else if (currentStatus != null) {
          final attendanceData = Attendance(
            studentId: student.id!,
            date: widget.date,
            status: currentStatus,
          );

          dev.log(
              'Saving attendance for student ${student.id}: ${attendanceData.toJson()}');

          await ApiService.post(
            createEndpoint,
            attendanceData.toJson(),
            Attendance.fromJson,
          );

          savedCount++;
          dev.log('Successfully saved attendance for student ${student.id}');
        }
        // Case 3: Status is null and no initial attendance - SKIP (nothing to do)
      }

      dev.log('Saved: $savedCount, Deleted: $deletedCount students');

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success

        String message = '';
        if (savedCount > 0 && deletedCount > 0) {
          message = 'تم حفظ $savedCount وحذف $deletedCount سجلات';
        } else if (savedCount > 0) {
          message = 'تم حفظ المواظبة بنجاح ($savedCount طالب)';
        } else if (deletedCount > 0) {
          message = 'تم حذف المواظبة ($deletedCount طالب)';
        } else {
          message = 'لا توجد تغييرات للحفظ';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e, stackTrace) {
      dev.log('Error saving bulk attendance: $e');
      dev.log('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ المواظبة: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF5350),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
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
                  const Expanded(
                    child: Text(
                      'المواظبة',
                      style: TextStyle(
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
            ),

            // Content
            Expanded(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status columns with checkboxes
                        ...widget.statusOptions.map((option) {
                          // Check if all students have this status
                          bool allSelected = widget.students.every((student) =>
                              student.id != null &&
                              selectedStatuses[student.id] == option['value']);

                          return Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _toggleSelectAllForStatus(
                                      option['value']),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: option['color']
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      allSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: option['color'],
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option['label'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(width: 16),
                        // Student name column
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'الطالب',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Students list
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.students.length,
                      itemBuilder: (context, index) {
                        final student = widget.students[index];
                        final studentName =
                            '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}';
                        final isEven = index % 2 == 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isEven ? Colors.grey.shade50 : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status radio buttons
                              ...widget.statusOptions.map((option) {
                                final isSelected =
                                    selectedStatuses[student.id] ==
                                        option['value'];
                                return Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedStatuses[student.id!] =
                                            option['value'];
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? option['color']
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 16),
                              // Student name
                              Expanded(
                                flex: 2,
                                child: Text(
                                  studentName,
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveAllAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB6AC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
