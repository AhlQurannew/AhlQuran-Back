import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:printing/printing.dart';

//
Future<Uint8List> generateReportPdf({
  required dynamic reportDataModel,
  required List<pw.Widget> Function({
    required dynamic reportDataModel,
    required pw.Font baseFont,
    required pw.Font boldFont,
    required pw.Font fallbackFont,
  }) buildContent,
  pw.Font? inputArabicFont,
  pw.Font? inputArabicFontBold,
  pw.Font? inputFallbackFont,
}) async {
  final pdf = pw.Document();

  // Load fonts if not provided
  final arabicFont = inputArabicFont ?? await PdfGoogleFonts.amiriRegular();
  final arabicFontBold =
      inputArabicFontBold ?? await PdfGoogleFonts.amiriBold();
  final fallbackFont =
      inputFallbackFont ?? await PdfGoogleFonts.notoSansArabicRegular();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: arabicFont,
        bold: arabicFontBold,
        fontFallback: [fallbackFont],
      ),
      build: (pw.Context context) {
        return buildContent(
          reportDataModel: reportDataModel,
          baseFont: arabicFont,
          boldFont: arabicFontBold,
          fallbackFont: fallbackFont,
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            textDirection: pw.TextDirection.rtl,
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(font: arabicFont, fontSize: 9),
          ),
        );
      },
    ),
  );

  return pdf.save();
}

Future<pw.Font> loadArabicFont() async {
  return await PdfGoogleFonts.amiriRegular();
}

Future<pw.Font> loadArabicBoldFont() async {
  return await PdfGoogleFonts.amiriBold();
}

Future<pw.Font> loadFallbackFont() async {
  return await PdfGoogleFonts.notoSansArabicRegular();
}
