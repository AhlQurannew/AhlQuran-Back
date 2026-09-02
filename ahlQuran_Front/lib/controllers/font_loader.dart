import 'package:pdf/widgets.dart' as pw;

import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/reports/pdf_generator.dart'
    as pdf_generator;

class FontController extends GetxController {
  late final pw.Font arabicFont;
  late final pw.Font arabicFontBold;
  late final pw.Font fallbackFont;

  @override
  void onInit() {
    super.onInit();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    arabicFont = await pdf_generator.loadArabicFont();
    arabicFontBold = await pdf_generator.loadArabicBoldFont();
    fallbackFont = await pdf_generator.loadFallbackFont();
  }
}
