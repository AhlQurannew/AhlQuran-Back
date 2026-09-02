import 'package:pdf/widgets.dart' as pw;
import 'table_helpers.dart';
import '../../system/new_models/reports/shared.dart';

pw.Widget buildTajweedAndRecitationSection(
  TajweedAndRecitationSchedule schedule,
  pw.Font font,
  pw.Font boldFont,
) {
  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        TableHelpers.buildStyledContainer(
          text: schedule.title,
          font: boldFont,
          backgroundColor: TableHelpers.primaryColor, // Use theme color
        ),
        _buildTajweedTable(schedule.lessons, font, boldFont),
      ],
    ),
  );
}

pw.Widget _buildTajweedTable(
  List<Lesson> lessons,
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
        text: 'التلقين',
        boldFont: boldFont,
        alignment: pw.Alignment.centerRight,
      ),
      TableHelpers.buildHeaderCell(
        text: 'التجويد',
        boldFont: boldFont,
        alignment: pw.Alignment.centerRight,
      ),
    ],
    columnWidths: {
      0: const pw.FlexColumnWidth(1), // Number
      1: const pw.FlexColumnWidth(2), // Day
      2: const pw.FlexColumnWidth(
        3,
      ), // Recitation Topic (wider for longer content)
      3: const pw.FlexColumnWidth(
        3,
      ), // Tajweed Topic (wider for longer content)
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
            text: lesson.recitationTopic,
            font: font,
            alignment: pw.Alignment.centerRight,
          ),
          TableHelpers.buildCell(
            text: lesson.tajweedTopic,
            font: font,
            alignment: pw.Alignment.centerRight,
          ),
        ],
      );
    }).toList(),
  );
}
