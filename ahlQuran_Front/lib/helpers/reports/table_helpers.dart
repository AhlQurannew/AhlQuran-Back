import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class TableHelpers {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFC78D20);
  static const PdfColor primaryContainer = PdfColor.fromInt(0xFFDEB059);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF8D9440);
  static const PdfColor secondaryContainer = PdfColor.fromInt(0xFFBFC39B);
  static const PdfColor tertiaryColor = PdfColor.fromInt(0xFF616247);
  static const PdfColor tertiaryContainer = PdfColor.fromInt(0xFFBCBCA8);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFB00020);
  static const PdfColor errorContainer = PdfColor.fromInt(0xFFFFDAD6);

  static pw.Widget buildHeaderCell({
    required String text,
    required pw.Font boldFont,
    int colSpan = 1,
    pw.Alignment alignment = pw.Alignment.centerRight,
    PdfColor backgroundColor = primaryContainer,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        //border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text, // Use a space if empty to ensure text area
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.right,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget buildCell({
    required String text,
    required pw.Font font,
    pw.Alignment alignment = pw.Alignment.centerRight,
    PdfColor? color,
    PdfColor backgroundColor = PdfColors.white,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        // border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text, // Use a space if empty to ensure text area
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: color ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.right,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget buildGradeCell(double score, pw.Font font) {
    final isLow = score < 10;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      alignment: pw.Alignment.centerRight,
      decoration: pw.BoxDecoration(
        color: isLow ? errorContainer : PdfColors.white,
        // border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
      ),
      child: pw.Text(
        score.toStringAsFixed(2),
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          fontWeight: isLow ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isLow ? errorColor : PdfColors.black,
        ),
        textAlign: pw.TextAlign.right,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget buildStyledContainer({
    required String text,
    required pw.Font font,
    pw.Alignment alignment = pw.Alignment.centerRight,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(
      vertical: 6,
      horizontal: 10,
    ),
    PdfColor backgroundColor = primaryColor,
    PdfColor textColor = PdfColors.white,
    double borderWidth = 0.5,
    pw.FontWeight fontWeight = pw.FontWeight.bold,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: padding,
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        //border: pw.Border.all(width: borderWidth, color: PdfColors.grey400),
      ),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          color: textColor,
          fontWeight: fontWeight,
          fontSize: 12,
        ),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  static pw.Widget buildCommonTable({
    required List<pw.Widget> headers,
    required List<pw.TableRow> rows,
    Map<int, pw.FlexColumnWidth>? columnWidths,
    double borderWidth = 0.5,
    PdfColor headerColor = secondaryContainer,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(width: borderWidth, color: PdfColors.grey400),
      columnWidths:
          columnWidths ??
          {
            for (int i = 0; i < headers.length; i++)
              i: const pw.FlexColumnWidth(1),
          },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: headers,
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget buildTopHeaderSection(String title, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const pw.BoxDecoration(color: primaryColor),
      child: pw.Text(
        title,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }
}
