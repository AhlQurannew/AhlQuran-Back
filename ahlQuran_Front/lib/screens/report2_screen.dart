import 'package:flutter/material.dart';
import '../helpers/reports/report_screen.dart';
import '../reports/report2.dart' as report2;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report2_model.dart'
    as model2;
import '../data/report2_data.dart' as data2;
import '../helpers/reports/pdf_generator.dart' as pdf_generator;

import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/font_loader.dart';

class Report2Screen extends StatelessWidget {
  final fonts = Get.find<FontController>();

  Report2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreen(
      title: 'تقرير ',
      generateReportPdf: (data) => pdf_generator.generateReportPdf(
        reportDataModel: data2.getFullAttendanceReport(),
        buildContent: ({
          required reportDataModel,
          required baseFont,
          required boldFont,
          required fallbackFont,
        }) {
          return report2.buildReport2Content(
            reportDataModel:
                reportDataModel as model2.FullAttendanceReport, // 👈 cast here
            baseFont: baseFont,
            boldFont: boldFont,
            fallbackFont: fallbackFont,
          );
        },
        inputArabicFont: fonts.arabicFont,
        inputArabicFontBold: fonts.arabicFontBold,
        inputFallbackFont: fonts.fallbackFont,
      ),
    );
  }
}
