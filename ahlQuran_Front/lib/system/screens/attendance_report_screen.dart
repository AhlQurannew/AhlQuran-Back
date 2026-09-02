import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../new_models/lecture.dart';
import '../new_models/student.dart';
import '../new_models/attendance.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import '../../helpers/date_picker.dart';
import 'base_layout.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  Lecture? lecture;
  String? startDate;
  String? endDate;
  List<Student> students = [];
  Map<int, Map<String, int>> attendanceStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Get parameters
    final parameters = Get.parameters;
    final lectureId = parameters['lectureId'];
    final lectureName = parameters['lectureName'];
    startDate = parameters['startDate'];
    endDate = parameters['endDate'];

    if (lectureId != null && lectureName != null) {
      lecture = Lecture(
        lectureId: int.tryParse(lectureId),
        lectureNameAr: lectureName,
      );
    }

    dev.log(
        'Lecture: ${lecture?.lectureNameAr}, Start: $startDate, End: $endDate');

    _loadData();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(12);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  Future<void> _loadData() async {
    try {
      if (lecture?.lectureId == null) {
        setState(() {
          students = [];
          isLoading = false;
        });
        return;
      }

      // Fetch students in the lecture
      final response = await ApiService.fetchList(
        '${ApiEndpoints.getStudents}?lecture_id=${lecture!.lectureId}',
        Student.fromJson,
      );

      setState(() {
        students = response;
      });

      // Load attendance statistics for each student
      await _loadAttendanceStats();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading data: $e');
      setState(() {
        students = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceStats() async {
    if (startDate == null || endDate == null) return;

    for (var student in students) {
      if (student.id != null) {
        try {
          // Fetch all attendance records for this student in the date range
          final attendances = await ApiService.fetchList(
            '${ApiEndpoints.getStudents}${student.id}/attendance?start_date=$startDate&end_date=$endDate',
            Attendance.fromJson,
          );

          // Calculate statistics
          final stats = {
            'present': 0,
            'late': 0,
            'absent': 0,
            'excused': 0,
          };

          for (var attendance in attendances) {
            stats[attendance.status] = (stats[attendance.status] ?? 0) + 1;
          }

          attendanceStats[student.id!] = stats;
        } catch (e) {
          dev.log('Error loading attendance for student ${student.id}: $e');
          attendanceStats[student.id!] = {
            'present': 0,
            'late': 0,
            'absent': 0,
            'excused': 0,
          };
        }
      }
    }
  }

  Future<void> _selectStartDate() async {
    DateTime initialDate;
    if (startDate != null && startDate!.isNotEmpty) {
      try {
        final parts = startDate!.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          initialDate = DateTime.now();
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final newDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        startDate = newDate;
        isLoading = true;
        attendanceStats.clear();
      });

      await _loadAttendanceStats();

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectEndDate() async {
    DateTime initialDate;
    if (endDate != null && endDate!.isNotEmpty) {
      try {
        final parts = endDate!.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          initialDate = DateTime.now();
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final newDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        endDate = newDate;
        isLoading = true;
        attendanceStats.clear();
      });

      await _loadAttendanceStats();

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicFontBold = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#DEB059'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'تقرير المواظبة',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.SizedBox(height: 16),
                // Info
                pw.Row(
                  children: [
                    pw.Text(
                      'من: ${startDate ?? ""} إلى: ${endDate ?? ""}',
                      style: pw.TextStyle(fontSize: 12, font: arabicFontBold),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 32),
                    pw.Text(
                      'الحلقة: ${lecture?.lectureNameAr ?? ""}',
                      style: pw.TextStyle(fontSize: 12, font: arabicFontBold),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#4DB6AC'),
                      ),
                      children: [
                        _buildPdfCell('الغيابات بعذر', arabicFontBold,
                            isHeader: true),
                        _buildPdfCell('الغيابات', arabicFontBold,
                            isHeader: true),
                        _buildPdfCell('التأخرات', arabicFontBold,
                            isHeader: true),
                        _buildPdfCell('الحضور', arabicFontBold, isHeader: true),
                        _buildPdfCell('الطالب', arabicFontBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...students.map((student) {
                      final stats = attendanceStats[student.id] ??
                          {
                            'present': 0,
                            'late': 0,
                            'absent': 0,
                            'excused': 0,
                          };
                      final index = students.indexOf(student);

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0
                              ? PdfColors.grey100
                              : PdfColors.white,
                        ),
                        children: [
                          _buildPdfCell('${stats['excused']}', arabicFont),
                          _buildPdfCell('${stats['absent']}', arabicFont),
                          _buildPdfCell('${stats['late']}', arabicFont),
                          _buildPdfCell('${stats['present']}', arabicFont),
                          _buildPdfCell(
                              '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                              arabicFont),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 14 : 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
          font: font,
          lineSpacing: 2,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        softWrap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "تقرير المواظبة",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Lecture and Date info
            _buildInfoBar(theme),

            const SizedBox(height: 16),

            // Attendance table
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAttendanceTable(theme),
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
            'تقرير المواظبة',
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
            width: 300,
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
          // Start Date
          InkWell(
            onTap: _selectStartDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 180,
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
                    'من',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      startDate ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // End Date
          InkWell(
            onTap: _selectEndDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 180,
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
                    'إلى',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      endDate ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Export button
          ElevatedButton.icon(
            onPressed: students.isEmpty ? null : _exportToPdf,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('تصدير PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(ThemeData theme) {
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
                  flex: 2,
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
                  flex: 1,
                  child: Text(
                    'الحضور',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'التأخرات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الغيابات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الغيابات بعذر',
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
                final stats = attendanceStats[student.id] ??
                    {
                      'present': 0,
                      'late': 0,
                      'absent': 0,
                      'excused': 0,
                    };
                final isEven = index % 2 == 0;

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
                      // Student name
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Present
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${stats['present']}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Late
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${stats['late']}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Absent
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${stats['absent']}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Excused
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${stats['excused']}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
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
