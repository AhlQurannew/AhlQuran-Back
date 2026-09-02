import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report2_model.dart';
import '../helpers/reports/table_helpers.dart';
import '../helpers/reports/info_section.dart';
import '../system/new_models/reports/shared.dart';

List<pw.Widget> buildReport2Content({
  required dynamic reportDataModel,
  required pw.Font baseFont,
  required pw.Font boldFont,
  required pw.Font fallbackFont,
}) {
  final fullReport = reportDataModel as FullAttendanceReport;

  return [
    pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          TableHelpers.buildTopHeaderSection(fullReport.reportTitle, boldFont),
          pw.SizedBox(height: 10),
          buildInfoTableSection(
            HeaderInfo(
              schoolName: fullReport.details.schoolName,
              teacherName: fullReport.details.teacherName,
              lectureName: fullReport.details.lectureName,
              reportPeriodHijri: fullReport.details.hijriDate,
              reportPeriodGregorian: fullReport.details.gregorianDate,
              categoryName: fullReport.details.reportType,
            ),
            baseFont,
            boldFont,
          ),
          pw.SizedBox(height: 15),
          buildAttendanceTable(
            baseFont,
            boldFont,
            fullReport.students,
            fallbackFont,
          ),
        ],
      ),
    ),
  ];
}

pw.Widget buildAttendanceTable(
  pw.Font arabicFont,
  pw.Font arabicFontBold,
  List<AttendanceStudent> students,
  pw.Font fallbackFont,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      TableHelpers.buildStyledContainer(
        text: 'سجل الحضور',
        font: arabicFontBold,
        backgroundColor: TableHelpers.primaryColor,
      ),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FixedColumnWidth(50),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: TableHelpers.secondaryContainer,
            ),
            children: [
              TableHelpers.buildHeaderCell(
                text: 'رقم الطالب',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'الاسم',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'حاضر',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'متأخر',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'غائب',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
              TableHelpers.buildHeaderCell(
                text: 'غياب بعذر',
                boldFont: arabicFontBold,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
          ...students.asMap().entries.map(
                (entry) => pw.TableRow(
                  children: [
                    TableHelpers.buildCell(
                      text: entry.value.studentId,
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                    TableHelpers.buildCell(
                      text: entry.value.name,
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                    TableHelpers.buildCell(
                      text: entry.value.presentCount.toString(),
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                    TableHelpers.buildCell(
                      text: entry.value.lateCount.toString(),
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                    TableHelpers.buildCell(
                      text: entry.value.absentCount.toString(),
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                    TableHelpers.buildCell(
                      text: entry.value.excusedAbsentCount.toString(),
                      font: arabicFont,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
              ),
        ],
      ),
    ],
  );
}
