/// Builds the top header section of the PDF report.
library;

import 'package:pdf/widgets.dart' as pw;

pw.Widget buildTopHeaderSection(
  String title, {
  required pw.Font arabicFontBold,
}) {
  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: arabicFontBold,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
