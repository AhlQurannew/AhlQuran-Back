import 'package:flutter/material.dart';
import '../helpers/reports/report_screen.dart';
import '../reports/report4.dart' as report4;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report4_model.dart'
    as model4;
import '../data/report4_data.dart' as data4;
import '../helpers/reports/pdf_generator.dart' as pdf_generator;

import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/font_loader.dart';

class Report4Screen extends StatelessWidget {
  final fonts = Get.find<FontController>();

  Report4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreen(
      title: 'تقرير الإنجاز',
      generateReportPdf: (data) => pdf_generator.generateReportPdf(
        reportDataModel: data4.createSampleData(),
        buildContent: ({
          required reportDataModel,
          required baseFont,
          required boldFont,
          required fallbackFont,
        }) {
          return report4.buildReport4Content(
            reportDataModel:
                reportDataModel as model4.ReportDataModel, // 👈 cast here
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
