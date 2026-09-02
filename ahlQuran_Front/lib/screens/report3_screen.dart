import 'package:flutter/material.dart';
import '../helpers/reports/report_screen.dart';
import '../reports/report3.dart' as report3;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/report3_model.dart'
    as model3;
import '../data/report3_data.dart' as data3;
import '../helpers/reports/pdf_generator.dart' as pdf_generator;
import '../system/new_models/reports/shared.dart' as shared;

import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/font_loader.dart';

class Report3Screen extends StatelessWidget {
  final fonts = Get.find<FontController>();

  Report3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreen(
      title: 'تقرير ',
      generateReportPdf: (data) => pdf_generator.generateReportPdf(
        reportDataModel: data3.createSampleReport(),
        buildContent: ({
          required reportDataModel,
          required baseFont,
          required boldFont,
          required fallbackFont,
        }) {
          return report3.buildReport3Content(
            reportDataModel: reportDataModel
                as shared.FullReport<model3.OverallSummary3>, // 👈 cast here
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
