import 'dart:io'; // For File
import 'dart:ui' as ui; // For ui.Image, ui.ImageByteFormat
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart'; // For general Flutter widgets
import 'package:path_provider/path_provider.dart'; // For getApplicationDocumentsDirectory
import 'package:flutter/rendering.dart'; // For RenderRepaintBoundary
import 'snackbar_helper.dart'; // For snackbar utilities

Future<void> downloadChart(GlobalKey chartKey, BuildContext context) async {
  try {
    final boundary =
        chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    if (boundary.debugNeedsPaint) {
      throw Exception("الرسم البياني غير جاهز، حاول مرة أخرى.");
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception("فشل في تحويل الصورة إلى بايت.");

    final pngBytes = byteData.buffer.asUint8List();

    if (kIsWeb) {
      showInfoSnackbar("التنزيل غير مدعوم في المعاينة على الويب.");
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = File(
      '${directory.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await imagePath.writeAsBytes(pngBytes);

    showSuccessSnackbar("تم حفظ الرسم البياني في: ${imagePath.path}");
  } catch (e) {
    showErrorSnackbar("فشل في حفظ الرسم البياني: ${e.toString()}");
  }
}
