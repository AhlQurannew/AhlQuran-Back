import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../new_models/lecture.dart';
import '../new_models/achievement.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import '../../helpers/date_picker.dart';
import 'base_layout.dart';

class StudentDetailReportScreen extends StatefulWidget {
  const StudentDetailReportScreen({super.key});

  @override
  State<StudentDetailReportScreen> createState() =>
      _StudentDetailReportScreenState();
}

class _StudentDetailReportScreenState extends State<StudentDetailReportScreen> {
  Lecture? lecture;
  String? date;
  int? studentId;
  String? studentName;
  List<Achievement> achievements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Get parameters
    final parameters = Get.parameters;
    final lectureId = parameters['lectureId'];
    final lectureName = parameters['lectureName'];
    date = parameters['date'];
    studentId = int.tryParse(parameters['studentId'] ?? '');
    studentName = parameters['studentName'];

    if (lectureId != null && lectureName != null) {
      lecture = Lecture(
        lectureId: int.tryParse(lectureId),
        lectureNameAr: lectureName,
      );
    }

    dev.log(
        'Student: $studentName, Lecture: ${lecture?.lectureNameAr}, Date: $date');

    _loadData();

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

  Future<void> _loadData() async {
    try {
      if (studentId == null) {
        setState(() {
          achievements = [];
          isLoading = false;
        });
        return;
      }

      // Load achievements for this student on this date
      final response = await ApiService.fetchList(
        '${ApiEndpoints.getStudents}$studentId/achievements?date=$date',
        Achievement.fromJson,
      );

      setState(() {
        achievements = response;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading data: $e');
      setState(() {
        achievements = [];
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initialDate;
    if (date != null && date!.isNotEmpty) {
      try {
        final parts = date!.split('-');
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
        date = newDate;
        isLoading = true;
        achievements.clear();
      });

      await _loadData();
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

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
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#DEB059'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'التقرير التفصيلي للطالب',
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
                    pw.SizedBox(width: 32),
                    pw.Text(
                      'الطالب: ${studentName ?? ""}',
                      style: pw.TextStyle(fontSize: 12, font: arabicFontBold),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
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
                      ],
                    ),
                    ...achievements.map((achievement) {
                      final index = achievements.indexOf(achievement);
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0
                              ? PdfColors.grey100
                              : PdfColors.white,
                        ),
                        children: [
                          _buildPdfCell(achievement.note ?? '--', arabicFont),
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
        title: "التقرير التفصيلي للطالب",
        child: Column(
          children: [
            _buildHeaderBar(theme),
            const SizedBox(height: 16),
            _buildInfoBar(theme),
            const SizedBox(height: 16),
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
            'التقرير التفصيلي للطالب',
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
                  'الطالب',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    studentName ?? '',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
          ElevatedButton.icon(
            onPressed: achievements.isEmpty ? null : _exportToPdf,
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
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد إنجاز لهذا الطالب في هذا التاريخ',
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
          Expanded(
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
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
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getAchievementTypeArabic(
                              achievement.achievementType),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${achievement.getFromSurahName()} ${achievement.fromVerse}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${achievement.getToSurahName()} ${achievement.toVerse}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
