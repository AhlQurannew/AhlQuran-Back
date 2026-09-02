import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../new_models/teacher.dart';
import '../new_models/teacher_attendance.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class TeacherAttendanceListScreen extends StatefulWidget {
  const TeacherAttendanceListScreen({super.key});

  @override
  State<TeacherAttendanceListScreen> createState() =>
      _TeacherAttendanceListScreenState();
}

class _TeacherAttendanceListScreenState
    extends State<TeacherAttendanceListScreen> {
  String? date;
  List<Teacher> teachers = [];
  Map<int, TeacherAttendance?> attendanceRecords = {};
  bool isLoading = true;

  final List<Map<String, dynamic>> statusOptions = [
    {'value': 'present', 'label': 'حضور', 'color': Color(0xFF4CAF50)},
    {'value': 'late', 'label': 'تأخر', 'color': Color(0xFFFFA726)},
    {'value': 'absent', 'label': 'غياب', 'color': Color(0xFFEF5350)},
    {'value': 'excused', 'label': 'عذر', 'color': Color(0xFF42A5F5)},
  ];

  @override
  void initState() {
    super.initState();

    // Get date from query parameters
    final parameters = Get.parameters;
    date = parameters['date'];

    dev.log('Date: $date');

    _loadTeachers();

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

  Future<void> _loadTeachers() async {
    try {
      // Fetch all teachers
      final response = await ApiService.fetchList(
        ApiEndpoints.getTeachers,
        Teacher.fromJson,
      );

      setState(() {
        teachers = response;
      });

      // Load attendance records for each teacher
      await _loadAttendanceRecords();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading teachers: $e');
      setState(() {
        teachers = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (date == null) return;

    for (var teacher in teachers) {
      if (teacher.teacherId != null) {
        try {
          final attendances = await ApiService.fetchList(
            '${ApiEndpoints.getTeachers}${teacher.teacherId}/attendance?date=$date',
            TeacherAttendance.fromJson,
          );

          if (attendances.isNotEmpty) {
            attendanceRecords[teacher.teacherId!] = attendances.first;
          } else {
            attendanceRecords[teacher.teacherId!] = null;
          }
        } catch (e) {
          dev.log(
              'Error loading attendance for teacher ${teacher.teacherId}: $e');
          attendanceRecords[teacher.teacherId!] = null;
        }
      }
    }
  }

  void _showBulkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => _BulkTeacherAttendanceDialog(
        teachers: teachers,
        date: date ?? '',
        initialAttendanceRecords: Map.from(attendanceRecords),
        statusOptions: statusOptions,
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
        title: "متابعة مواظبة المعلمين",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Date info
            _buildInfoBar(theme),

            const SizedBox(height: 16),

            // Action button
            _buildActionButton(theme),

            const SizedBox(height: 16),

            // Teachers table
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTeachersTable(theme),
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

  Widget _buildInfoBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
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

  Widget _buildTeachersTable(ThemeData theme) {
    if (teachers.isEmpty) {
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
              'لا يوجد معلمين',
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
                    'المعلم',
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
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                final isEven = index % 2 == 0;
                final attendance = attendanceRecords[teacher.teacherId];

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
                      // Teacher name
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${teacher.firstName ?? ''} ${teacher.lastName ?? ''}',
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

// Bulk Teacher Attendance Dialog Widget
class _BulkTeacherAttendanceDialog extends StatefulWidget {
  final List<Teacher> teachers;
  final String date;
  final Map<int, TeacherAttendance?> initialAttendanceRecords;
  final List<Map<String, dynamic>> statusOptions;

  const _BulkTeacherAttendanceDialog({
    required this.teachers,
    required this.date,
    required this.initialAttendanceRecords,
    required this.statusOptions,
  });

  @override
  State<_BulkTeacherAttendanceDialog> createState() =>
      _BulkTeacherAttendanceDialogState();
}

class _BulkTeacherAttendanceDialogState
    extends State<_BulkTeacherAttendanceDialog> {
  late Map<int, String?> selectedStatuses;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected statuses from existing attendance records
    selectedStatuses = {};
    for (var teacher in widget.teachers) {
      if (teacher.teacherId != null) {
        final attendance = widget.initialAttendanceRecords[teacher.teacherId];
        selectedStatuses[teacher.teacherId!] = attendance?.status;
      }
    }
  }

  void _toggleSelectAllForStatus(String status) {
    setState(() {
      // Check if all teachers already have this status
      bool allHaveStatus = widget.teachers.every((teacher) =>
          teacher.teacherId != null &&
          selectedStatuses[teacher.teacherId] == status);

      if (allHaveStatus) {
        // Deselect all - clear the status for all teachers
        for (var teacher in widget.teachers) {
          if (teacher.teacherId != null) {
            selectedStatuses[teacher.teacherId!] = null;
          }
        }
      } else {
        // Select all - set this status for all teachers
        for (var teacher in widget.teachers) {
          if (teacher.teacherId != null) {
            selectedStatuses[teacher.teacherId!] = status;
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
          'Starting to save attendance for ${widget.teachers.length} teachers');
      dev.log('Selected statuses: $selectedStatuses');

      int savedCount = 0;
      int deletedCount = 0;

      // Process each teacher
      for (var teacher in widget.teachers) {
        if (teacher.teacherId == null) continue;

        final currentStatus = selectedStatuses[teacher.teacherId!];
        final initialAttendance =
            widget.initialAttendanceRecords[teacher.teacherId!];

        // Case 1: Status is null and there was an initial attendance - DELETE
        if (currentStatus == null && initialAttendance != null) {
          dev.log('Deleting attendance for teacher ${teacher.teacherId}');

          try {
            await ApiService.delete(
              '${ApiEndpoints.getTeachers}${teacher.teacherId}/attendance/${initialAttendance.id}',
            );
            deletedCount++;
            dev.log(
                'Successfully deleted attendance for teacher ${teacher.teacherId}');
          } catch (e) {
            dev.log(
                'Error deleting attendance for teacher ${teacher.teacherId}: $e');
            // Continue with other teachers even if one fails
          }
        }
        // Case 2: Status is not null - SAVE/UPDATE
        else if (currentStatus != null) {
          final attendanceData = TeacherAttendance(
            teacherId: teacher.teacherId!,
            date: widget.date,
            status: currentStatus,
          );

          dev.log(
              'Saving attendance for teacher ${teacher.teacherId}: ${attendanceData.toJson()}');

          await ApiService.post(
            '${ApiEndpoints.getTeachers}${teacher.teacherId}/attendance',
            attendanceData.toJson(),
            TeacherAttendance.fromJson,
          );

          savedCount++;
          dev.log(
              'Successfully saved attendance for teacher ${teacher.teacherId}');
        }
        // Case 3: Status is null and no initial attendance - SKIP (nothing to do)
      }

      dev.log('Saved: $savedCount, Deleted: $deletedCount teachers');

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success

        String message = '';
        if (savedCount > 0 && deletedCount > 0) {
          message = 'تم حفظ $savedCount وحذف $deletedCount سجلات';
        } else if (savedCount > 0) {
          message = 'تم حفظ المواظبة بنجاح ($savedCount معلم)';
        } else if (deletedCount > 0) {
          message = 'تم حذف المواظبة ($deletedCount معلم)';
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
      dev.log('Error saving bulk teacher attendance: $e');
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
                          // Check if all teachers have this status
                          bool allSelected = widget.teachers.every((teacher) =>
                              teacher.teacherId != null &&
                              selectedStatuses[teacher.teacherId] ==
                                  option['value']);

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
                        // Teacher name column
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'المعلم',
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

                  // Teachers list
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = widget.teachers[index];
                        final teacherName =
                            '${teacher.firstName ?? ''} ${teacher.lastName ?? ''}';
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
                                    selectedStatuses[teacher.teacherId] ==
                                        option['value'];
                                return Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedStatuses[teacher.teacherId!] =
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
                              // Teacher name
                              Expanded(
                                flex: 2,
                                child: Text(
                                  teacherName,
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
