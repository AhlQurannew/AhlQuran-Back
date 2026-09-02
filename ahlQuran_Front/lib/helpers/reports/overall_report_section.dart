import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report1_model.dart';

pw.Widget buildOverallReportSection(
  pw.Font arabicFont,
  pw.Font arabicFontBold,
  OverallSummary1 summary,
) {
  final overallSummary = [
    summary.studyCircleStudentCount,
    summary.reinforcementLog,
    summary.memorizationPages,
    summary.reviewPages,
  ];

  return pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey700,
            border: pw.Border.all(width: 0.5),
          ),
          child: pw.Text(
            'الإجمالي',
            style: pw.TextStyle(
              font: arabicFontBold,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: overallSummary.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    item.label,
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.TableRow(
              children: overallSummary.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    item.value.toString(),
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    ),
  );
}
