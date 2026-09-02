import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../new_models/lecture.dart';
import '../new_models/student.dart';
import '../new_models/achievement.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import '../../helpers/date_picker.dart';
import 'base_layout.dart';

class DailyAchievementReportScreen extends StatefulWidget {
  const DailyAchievementReportScreen({super.key});

  @override
  State<DailyAchievementReportScreen> createState() =>
      _DailyAchievementReportScreenState();
}

class _DailyAchievementReportScreenState
    extends State<DailyAchievementReportScreen> {
  Lecture? lecture;
  String? date;
  List<Student> students = [];
  List<Lecture> allLectures = [];
  Map<int, List<Achievement>> studentAchievements = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Get parameters
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

    dev.log('Lecture: ${lecture?.lectureNameAr}, Date: $date');

    _init();

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

  Future<void> _init() async {
    await _loadLectures();
    await _loadData();
  }

  Future<void> _loadLectures() async {
    try {
      dev.log('Loading lectures from: ${ApiEndpoints.getSpecialLectures}');
      final response = await ApiService.fetchList(
        ApiEndpoints.getSpecialLectures,
        Lecture.fromJson,
      );

      dev.log('Lectures loaded successfully. Count: ${response.length}');
      setState(() {
        allLectures = response;
      });
    } catch (e) {
      dev.log('Error loading lectures: $e');
      setState(() {
        allLectures = [];
      });
    }
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

      // Load achievements for each student on this date
      await _loadAchievements();

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

  Future<void> _loadAchievements() async {
    if (date == null) return;

    for (var student in students) {
      if (student.id != null) {
        try {
          // Pass date parameter to API for server-side filtering
          final achievements = await ApiService.fetchList(
            '${ApiEndpoints.getStudents}${student.id}/achievements?date=$date',
            Achievement.fromJson,
          );

          studentAchievements[student.id!] = achievements;
        } catch (e) {
          dev.log('Error loading achievements for student ${student.id}: $e');
          studentAchievements[student.id!] = [];
        }
      }
    }
  }

  Future<void> _selectLecture() async {
    dev.log('Lecture box clicked. allLectures count: ${allLectures.length}');

    if (allLectures.isEmpty) {
      dev.log('No lectures loaded, showing snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل الحلقات...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final Lecture? selected = await showDialog<Lecture>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'اختر الحلقة',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allLectures.length,
              itemBuilder: (context, index) {
                final lec = allLectures[index];
                final isSelected = lec.lectureId == lecture?.lectureId;
                return ListTile(
                  title: Text(
                    lec.lectureNameAr ?? '',
                    textAlign: TextAlign.right,
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  onTap: () {
                    Navigator.of(context).pop(lec);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );

    if (selected != null && selected.lectureId != lecture?.lectureId) {
      setState(() {
        lecture = selected;
        isLoading = true;
        students = [];
        studentAchievements.clear();
      });

      // Reload data with new lecture
      await _loadData();
    }
  }

  Future<void> _selectDate() async {
    // Parse current date from DD-MM-YYYY format
    DateTime initialDate;
    if (date != null && date!.isNotEmpty) {
      try {
        final parts = date!.split('-');
        if (parts.length == 3) {
          // Date is in DD-MM-YYYY format
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
      // Format date as DD-MM-YYYY
      final newDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        date = newDate;
        isLoading = true;
        studentAchievements.clear();
      });

      // Reload achievements with new date
      await _loadAchievements();

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "تقرير الإنجاز اليومي",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Lecture and Date info
            _buildInfoBar(theme),

            const SizedBox(height: 16),

            // Achievements table
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAchievementsTable(theme),
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
            'تقرير الإنجاز اليومي',
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

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    // Load Arabic font that supports tashkeel
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
                    'تقرير الإنجاز اليومي',
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
                      'التاريخ: ${date ?? ""}',
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
                        _buildPdfCell('الدرجة', arabicFontBold, isHeader: true),
                        _buildPdfCell('إلى', arabicFontBold, isHeader: true),
                        _buildPdfCell('من', arabicFontBold, isHeader: true),
                        _buildPdfCell('نوع الإنجاز', arabicFontBold,
                            isHeader: true),
                        _buildPdfCell('الطالب', arabicFontBold, isHeader: true),
                        _buildPdfCell('#', arabicFontBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...students.asMap().entries.expand((entry) {
                      final index = entry.key;
                      final student = entry.value;
                      final achievements =
                          studentAchievements[student.id] ?? [];

                      if (achievements.isNotEmpty) {
                        return achievements.map((achievement) {
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: index % 2 == 0
                                  ? PdfColors.grey100
                                  : PdfColors.white,
                            ),
                            children: [
                              _buildPdfCell(
                                  achievement.note ?? '--', arabicFont),
                              _buildPdfCell(
                                  '${achievement.getToSurahName()} ${achievement.toVerse}',
                                  arabicFont),
                              _buildPdfCell(
                                  '${achievement.getFromSurahName()} ${achievement.fromVerse}',
                                  arabicFont),
                              _buildPdfCell(
                                  _getAchievementTypeArabic(
                                      achievement.achievementType),
                                  arabicFont),
                              _buildPdfCell(
                                  '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                                  arabicFont),
                              _buildPdfCell('${index + 1}', arabicFont),
                            ],
                          );
                        }).toList();
                      } else {
                        return [
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: index % 2 == 0
                                  ? PdfColors.grey100
                                  : PdfColors.white,
                            ),
                            children: [
                              _buildPdfCell('--', arabicFont),
                              _buildPdfCell('--', arabicFont),
                              _buildPdfCell('--', arabicFont),
                              _buildPdfCell('--', arabicFont),
                              _buildPdfCell(
                                  '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                                  arabicFont),
                              _buildPdfCell('${index + 1}', arabicFont),
                            ],
                          ),
                        ];
                      }
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

  pw.Widget _buildPdfCell(String text, pw.Font font,
      {bool isHeader = false, int colSpan = 1}) {
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

  Widget _buildInfoBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Lecture
          InkWell(
            onTap: _selectLecture,
            borderRadius: BorderRadius.circular(8),
            child: Container(
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
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
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
                  Expanded(
                    child: Text(
                      date ?? '',
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

  Widget _buildAchievementsTable(ThemeData theme) {
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
                  flex: 2,
                  child: Text(
                    'نوع الإنجاز',
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
                    'من',
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
                    'إلى',
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
                    'الدرجة',
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
                final achievements = studentAchievements[student.id] ?? [];
                final isEven = index % 2 == 0;

                // If student has achievements, show them
                if (achievements.isNotEmpty) {
                  return Column(
                    children: achievements.map((achievement) {
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
                              flex: 2,
                              child: Text(
                                '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Achievement type
                            Expanded(
                              flex: 2,
                              child: Text(
                                _getAchievementTypeArabic(
                                    achievement.achievementType),
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // From
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${achievement.getFromSurahName()} ${achievement.fromVerse}',
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // To
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${achievement.getToSurahName()} ${achievement.toVerse}',
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Grade (placeholder)
                            Expanded(
                              flex: 2,
                              child: Text(
                                achievement.note ?? '--',
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  // Show student with no achievements
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
                          flex: 2,
                          child: Text(
                            '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // No achievements
                        const Expanded(
                          flex: 8,
                          child: Text(
                            'لا يوجد إنجاز',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getAchievementTypeArabic(String type) {
    switch (type) {
      case 'normal':
        return 'الحفظ';
      case 'small':
        return 'المراجعة';
      case 'big':
        return 'التثبيت';
      default:
        return type;
    }
  }
}
