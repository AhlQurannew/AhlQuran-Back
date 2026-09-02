import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report4_model.dart';
import '../helpers/reports/accompanying_curriculum_section.dart';
import '../helpers/reports/tjweed_section.dart';
import '../helpers/reports/table_helpers.dart';
import '../helpers/reports/info_section.dart';

List<pw.Widget> buildReport4Content({
  required dynamic reportDataModel,
  required pw.Font baseFont,
  required pw.Font boldFont,
  required pw.Font fallbackFont,
}) {
  return [
    pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          TableHelpers.buildTopHeaderSection(
            reportDataModel.reportData.headerInfo.lectureName,
            boldFont,
          ),
          pw.SizedBox(height: 10),
          buildInfoTableSection(
            reportDataModel.reportData.headerInfo,
            baseFont,
            boldFont,
          ),
          pw.SizedBox(height: 15),
          buildOverallReportSection(
            reportDataModel.reportData.summaryReport,
            reportDataModel.reportData.detailedReport,
            baseFont,
            boldFont,
            fallbackFont,
          ),
          pw.SizedBox(height: 15),
          buildStudentPerformanceTable(
            reportDataModel,
            baseFont,
            boldFont,
            fallbackFont,
          ),
          pw.SizedBox(height: 15),
          buildTajweedAndRecitationSection(
            reportDataModel.curriculumSchedule.tajweedAndRecitationSchedule,
            baseFont,
            boldFont,
          ),
          pw.SizedBox(height: 15),
          buildAccompanyingCurriculumSection(
            reportDataModel.curriculumSchedule.accompanyingCurriculum,
            baseFont,
            boldFont,
          ),
        ],
      ),
    ),
  ];
}

pw.Widget buildOverallReportSection(
  SummaryReport summary,
  List<DetailedReport> detailedReports,
  pw.Font baseFont,
  pw.Font boldFont,
  pw.Font fallbackFont,
) {
  double totalMemorizationPartsAvg = 0.0;
  int memorizationCount = 0;
  double totalReviewPartsAvg = 0.0;
  int reviewCount = 0;
  double totalFixationPartsAvg = 0.0;
  int fixationCount = 0;

  for (var report in detailedReports) {
    totalMemorizationPartsAvg += report.memorization.value;
    memorizationCount++;
    totalReviewPartsAvg += report.review.value;
    reviewCount++;
    totalFixationPartsAvg += report.fixation.value;
    fixationCount++;
  }

  final double avgMemorizationParts = memorizationCount > 0
      ? totalMemorizationPartsAvg / memorizationCount
      : 0.0;
  final double avgReviewParts =
      reviewCount > 0 ? totalReviewPartsAvg / reviewCount : 0.0;
  final double avgFixationParts =
      fixationCount > 0 ? totalFixationPartsAvg / fixationCount : 0.0;

  final String consistencyRatio = detailedReports.isNotEmpty
      ? '${detailedReports[0].attendancePercentage.toStringAsFixed(1)}%'
      : '0%';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      TableHelpers.buildStyledContainer(
        text: 'التفاصيل',
        font: boldFont,
        backgroundColor: TableHelpers.primaryColor,
      ),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
        columnWidths: {
          for (int i = 0; i < 6; i++) i: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: TableHelpers.secondaryContainer,
            ),
            children: [
              TableHelpers.buildHeaderCell(
                text: 'عدد أيام الدوام',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'عدد الطلاب',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'معدل أجزاء الحفظ',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'معدل أجزاء المراجعة',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'نسبة المواظبة',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'معدل أجزاء التثبيت',
                boldFont: boldFont,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
          pw.TableRow(
            children: [
              TableHelpers.buildCell(
                text: summary.attendanceDaysCount.toString(),
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildCell(
                text: detailedReports.length.toString(),
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildCell(
                text: avgMemorizationParts.toStringAsFixed(2),
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildCell(
                text: avgReviewParts.toStringAsFixed(2),
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildCell(
                text: consistencyRatio,
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildCell(
                text: avgFixationParts.toStringAsFixed(2),
                font: baseFont,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

pw.Widget buildStudentPerformanceTable(
  ReportDataModel reportDataModel,
  pw.Font baseFont,
  pw.Font boldFont,
  pw.Font fallbackFont,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      TableHelpers.buildStyledContainer(
        text: 'أداء الطلاب', // "Student Performance"
        font: boldFont,
        backgroundColor: TableHelpers.primaryColor,
      ),
      _buildPerformanceTableHeader(boldFont),
      ...reportDataModel.reportData.detailedReport.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final student = entry.value;
        return _buildPerformanceDataRow(
          index,
          student,
          reportDataModel.reportData.summaryReport.attendanceDaysCount,
          baseFont,
          boldFont,
          fallbackFont,
        );
      }),
    ],
  );
}

pw.Widget _buildPerformanceTableHeader(pw.Font boldFont) {
  return pw.Column(
    children: [
      _buildPerformanceTableHeaderTopRow(boldFont),
      _buildPerformanceTableHeaderSubRow(boldFont),
    ],
  );
}

pw.Widget _buildPerformanceTableHeaderTopRow(pw.Font boldFont) {
  return pw.Table(
    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FixedColumnWidth(20), // Number
      1: const pw.FlexColumnWidth(3), // Student Name
      2: const pw.FlexColumnWidth(3), // Memorization (3 columns)
      3: const pw.FlexColumnWidth(3), // Review (3 columns)
      4: const pw.FlexColumnWidth(3), // Fixation (3 columns)
      5: const pw.FixedColumnWidth(
        40,
      ), // Attendance Days (reduced from 50 to 40)
      6: const pw.FixedColumnWidth(
        40,
      ), // Skill Percentage (reduced from 50 to 40)
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: TableHelpers.secondaryContainer,
        ),
        children: [
          _buildDetailedHeaderCell('م', boldFont), // Number
          _buildDetailedHeaderCell('اسم الطالب', boldFont), // Student Name
          _buildDetailedHeaderCell('الحفظ', boldFont), // Memorization
          _buildDetailedHeaderCell('المراجعة', boldFont), // Review
          _buildDetailedHeaderCell('التثبيت', boldFont), // Fixation
          _buildDetailedHeaderCell(
            'أيام المواظبة',
            boldFont,
          ), // Attendance Days
          _buildDetailedHeaderCell(
            'نسبة المهارة',
            boldFont,
          ), // Skill Percentage
        ],
      ),
    ],
  );
}

pw.Widget _buildPerformanceTableHeaderSubRow(pw.Font boldFont) {
  return pw.Table(
    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FixedColumnWidth(20), // Number
      1: const pw.FlexColumnWidth(3), // Student Name
      2: const pw.FixedColumnWidth(
        35,
      ), // Memorization: Start (reduced from 40 to 35)
      3: const pw.FixedColumnWidth(
        35,
      ), // Memorization: Middle (reduced from 40 to 35)
      4: const pw.FixedColumnWidth(
        35,
      ), // Memorization: End (reduced from 40 to 35)
      5: const pw.FixedColumnWidth(35), // Review: Start (reduced from 40 to 35)
      6: const pw.FixedColumnWidth(
        35,
      ), // Review: Middle (reduced from 40 to 35)
      7: const pw.FixedColumnWidth(35), // Review: End (reduced from 40 to 35)
      8: const pw.FixedColumnWidth(
        35,
      ), // Fixation: Start (reduced from 40 to 35)
      9: const pw.FixedColumnWidth(
        35,
      ), // Fixation: Middle (reduced from 40 to 35)
      10: const pw.FixedColumnWidth(
        35,
      ), // Fixation: End (reduced from 40 to 35)
      11: const pw.FixedColumnWidth(
        40,
      ), // Attendance Days (reduced from 50 to 40)
      12: const pw.FixedColumnWidth(
        40,
      ), // Skill Percentage (reduced from 50 to 40)
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: TableHelpers.tertiaryContainer,
        ),
        children: [
          _buildDetailedHeaderCell('', boldFont),
          _buildDetailedHeaderCell('', boldFont),
          _buildDetailedHeaderCell('الصفحات ', boldFont), // Start
          _buildDetailedHeaderCell('الأجزاء', boldFont), // Middle
          _buildDetailedHeaderCell('الدرجة ', boldFont), // End
          _buildDetailedHeaderCell('الصفحات ', boldFont), // Start
          _buildDetailedHeaderCell('الأجزاء', boldFont), // Middle
          _buildDetailedHeaderCell('الدرجة ', boldFont), // End
          _buildDetailedHeaderCell('الصفحات ', boldFont), // Start
          _buildDetailedHeaderCell('الأجزاء', boldFont), // Middle
          _buildDetailedHeaderCell('الدرجة ', boldFont), // End
          _buildDetailedHeaderCell('', boldFont),
          _buildDetailedHeaderCell('', boldFont),
        ],
      ),
    ],
  );
}

pw.Widget _buildPerformanceDataRow(
  int index,
  DetailedReport student,
  int totalAttendanceDays,
  pw.Font baseFont,
  pw.Font boldFont,
  pw.Font fallbackFont,
) {
  final attendanceDays =
      ((student.attendancePercentage / 100) * totalAttendanceDays).round();

  String format(double? val) => val?.toStringAsFixed(2) ?? '0.00';

  return pw.Table(
    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FixedColumnWidth(20), // Number
      1: const pw.FlexColumnWidth(3), // Student Name
      2: const pw.FixedColumnWidth(
        35,
      ), // Memorization: Start (reduced from 40 to 35)
      3: const pw.FixedColumnWidth(
        35,
      ), // Memorization: Middle (reduced from 40 to 35)
      4: const pw.FixedColumnWidth(
        35,
      ), // Memorization: End (reduced from 40 to 35)
      5: const pw.FixedColumnWidth(35), // Review: Start (reduced from 40 to 35)
      6: const pw.FixedColumnWidth(
        35,
      ), // Review: Middle (reduced from 40 to 35)
      7: const pw.FixedColumnWidth(35), // Review: End (reduced from 40 to 35)
      8: const pw.FixedColumnWidth(
        35,
      ), // Fixation: Start (reduced from 40 to 35)
      9: const pw.FixedColumnWidth(
        35,
      ), // Fixation: Middle (reduced from 40 to 35)
      10: const pw.FixedColumnWidth(
        35,
      ), // Fixation: End (reduced from 40 to 35)
      11: const pw.FixedColumnWidth(
        40,
      ), // Attendance Days (reduced from 50 to 40)
      12: const pw.FixedColumnWidth(
        40,
      ), // Skill Percentage (reduced from 50 to 40)
    },
    children: [
      pw.TableRow(
        children: [
          _buildDetailedCell(
            index.toString(),
            baseFont,
            alignment: pw.Alignment.center,
          ),
          _buildDetailedCell(student.studentName, baseFont),
          _buildDetailedCell(format(student.memorization.count), baseFont),
          _buildDetailedCell(format(student.memorization.value), baseFont),
          TableHelpers.buildGradeCell(student.memorization.avg, baseFont),
          _buildDetailedCell(format(student.review.count), baseFont),
          _buildDetailedCell(format(student.review.value), baseFont),
          TableHelpers.buildGradeCell(student.review.avg, baseFont),
          _buildDetailedCell(format(student.fixation.count), baseFont),
          _buildDetailedCell(format(student.fixation.value), baseFont),
          TableHelpers.buildGradeCell(student.fixation.avg, baseFont),
          _buildDetailedCell(attendanceDays.toString(), baseFont),
          _buildDetailedCell(
            '${student.attendancePercentage.toStringAsFixed(1)}%',
            baseFont,
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildDetailedCell(
  String text,
  pw.Font font, {
  pw.Alignment alignment = pw.Alignment.centerRight,
}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    decoration: pw.BoxDecoration(
      color: PdfColors.white, // Uniform background color
      border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
    ),
    child: pw.Text(
      text.isEmpty ? ' ' : text, // Use a space if empty to fill the area
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(font: font, fontSize: 8),
      textAlign: pw.TextAlign.right,
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    ),
  );
}

pw.Widget _buildDetailedHeaderCell(
  String text,
  pw.Font boldFont, {
  pw.Alignment alignment = pw.Alignment.centerRight,
}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    decoration: pw.BoxDecoration(
      color: TableHelpers.secondaryContainer,
      border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
    ),
    child: pw.Text(
      text.isEmpty ? ' ' : text, // Use a space if empty to fill the area
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.right,
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    ),
  );
}
