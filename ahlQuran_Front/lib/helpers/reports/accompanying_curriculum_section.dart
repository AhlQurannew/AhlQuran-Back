import 'package:pdf/widgets.dart' as pw;
import 'table_helpers.dart';
import '../../system/new_models/reports/shared.dart';

pw.Widget buildAccompanyingCurriculumSection(
  AccompanyingCurriculum curriculum,
  pw.Font font,
  pw.Font boldFont,
) {
  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        TableHelpers.buildStyledContainer(
          text: curriculum.title,
          font: boldFont,
          backgroundColor: TableHelpers.primaryColor, // Use theme color
        ),
        _buildCurriculumTable(curriculum.lessons, font, boldFont),
      ],
    ),
  );
}

pw.Widget _buildCurriculumTable(
  List<AccompanyingLesson> lessons,
  pw.Font font,
  pw.Font boldFont,
) {
  return TableHelpers.buildCommonTable(
    headers: [
      TableHelpers.buildHeaderCell(
        text: 'م',
        boldFont: boldFont,
        alignment: pw.Alignment.center,
      ),
      TableHelpers.buildHeaderCell(
        text: 'اليوم',
        boldFont: boldFont,
        alignment: pw.Alignment.centerRight,
      ),
      TableHelpers.buildHeaderCell(
        text: 'المادة',
        boldFont: boldFont,
        alignment: pw.Alignment.centerRight,
      ),
      TableHelpers.buildHeaderCell(
        text: 'عنوان الدرس',
        boldFont: boldFont,
        alignment: pw.Alignment.centerRight,
      ),
    ],
    columnWidths: {
      0: const pw.FlexColumnWidth(1), // Number
      1: const pw.FlexColumnWidth(2), // Day
      2: const pw.FlexColumnWidth(2), // Subject
      3: const pw.FlexColumnWidth(3), // Lesson Title (wider for longer content)
    },
    rows: lessons.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final lesson = entry.value;
      return pw.TableRow(
        children: [
          TableHelpers.buildCell(
            text: index.toString(),
            font: font,
            alignment: pw.Alignment.center,
          ),
          TableHelpers.buildCell(
            text: lesson.day,
            font: font,
            alignment: pw.Alignment.centerRight,
          ),
          TableHelpers.buildCell(
            text: lesson.subject,
            font: font,
            alignment: pw.Alignment.centerRight,
          ),
          TableHelpers.buildCell(
            text: lesson.lessonTitle,
            font: font,
            alignment: pw.Alignment.centerRight,
          ),
        ],
      );
    }).toList(),
  );
}
