import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../system/new_models/reports/shared.dart';

/// Builds the information table section of the PDF report.
pw.Widget buildInfoTableSection(
  HeaderInfo headerInfo,
  pw.Font font,
  pw.Font boldFont,
) {
  const double cellPadding = 8.0;
  const double borderWidth = 0.5;
  const PdfColor headerColor = PdfColors.grey200;

  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(1), // Label column
        1: const pw.FlexColumnWidth(2.5), // Value column (wider for content)
        2: const pw.FlexColumnWidth(1), // Label column
        3: const pw.FlexColumnWidth(2.5), // Value column (wider for content)
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        // Row 1: School Name and Lecture Name
        buildTableRow(
          label1: 'اسم المدرسة',
          value1: headerInfo.schoolName,
          label2: 'اسم الحلقة',
          value2: headerInfo.lectureName,
          font: font,
          boldFont: boldFont,
          padding: cellPadding,
          backgroundColor: headerColor,
        ),
        // Row 2: Teacher Name and Category
        buildTableRow(
          label1: 'اسم المعلم',
          value1: headerInfo.teacherName,
          label2: 'فئة',
          value2: headerInfo.categoryName,
          font: font,
          boldFont: boldFont,
          padding: cellPadding,
          backgroundColor: headerColor,
        ),
        // Row 3: Gregorian and Hijri Dates
        buildTableRow(
          label1: 'التاريخ الميلادي',
          value1: headerInfo.reportPeriodGregorian,
          label2: 'التاريخ الهجري',
          value2: headerInfo.reportPeriodHijri,
          font: font,
          boldFont: boldFont,
          padding: cellPadding,
          backgroundColor: headerColor,
        ),
      ],
    ),
  );
}

// Helper function to build a table row
pw.TableRow buildTableRow({
  required String label1,
  required String value1,
  required String label2,
  required String value2,
  required pw.Font font,
  required pw.Font boldFont,
  required double padding,
  PdfColor? backgroundColor,
}) {
  return pw.TableRow(
    decoration: backgroundColor != null
        ? pw.BoxDecoration(color: backgroundColor)
        : null,
    children: [
      buildInfoTableCell(label1, boldFont, padding: padding),
      buildInfoTableCell(value1, font, padding: padding),
      buildInfoTableCell(label2, boldFont, padding: padding),
      buildInfoTableCell(value2, font, padding: padding),
    ],
  );
}

// Improved table cell builder
pw.Widget buildInfoTableCell(
  String text,
  pw.Font font, {
  required double padding,
}) {
  return pw.Container(
    padding: pw.EdgeInsets.symmetric(
      horizontal: padding,
      vertical: padding / 2,
    ),
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 10),
      textAlign: pw.TextAlign.right,
      softWrap: true,
    ),
  );
}
