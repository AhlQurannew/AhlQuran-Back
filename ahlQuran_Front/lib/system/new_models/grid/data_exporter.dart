import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../widgets/dialogs/platform_utils.dart';
import '../../utils/snackbar_helper.dart';

class DataExporter {
  /// Exports [data] to an Excel file with the provided [columns] and [rowBuilder].
  ///
  /// Saves the file in a temporary directory and opens it using the system's default app.
  /// Provides user feedback through snackbars.
  static Future<void> exportToExcel<T>({
    required BuildContext context,
    required List<T> data,
    required List<GridColumn> columns,
    required DataGridRow Function(T) rowBuilder,
  }) async {
    if (!PlatformUtils.isDesktop) {
      showErrorSnackbar('التصدير متاح فقط لإصدارات سطح المكتب');
      return;
    }

    try {
      showInfoSnackbar('جاري إنشاء الملف...');

      final workbook = Workbook();
      final sheet = workbook.worksheets[0];

      _writeHeaders(sheet, columns);
      _writeData(sheet, data, rowBuilder);

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final filePath = await _saveFile(bytes, 'exported_data.xlsx');
      await _openFile(filePath);

      showSuccessSnackbar('تم حفظ الملف بنجاح في: $filePath');
    } catch (e) {
      showErrorSnackbar('حدث خطأ أثناء التصدير: $e');
    }
  }

  /// Writes column headers in the first row of the Excel sheet.
  static void _writeHeaders(Worksheet sheet, List<GridColumn> columns) {
    for (int c = 0; c < columns.length; c++) {
      sheet.getRangeByIndex(1, c + 1).setText(columns[c].columnName);
    }
  }

  /// Writes data rows starting from the second row.
  static void _writeData<T>(
      Worksheet sheet, List<T> data, DataGridRow Function(T) rowBuilder) {
    for (int r = 0; r < data.length; r++) {
      final row = rowBuilder(data[r]);
      final cells = row.getCells();
      for (int c = 0; c < cells.length; c++) {
        sheet.getRangeByIndex(r + 2, c + 1).setText(cells[c].value.toString());
      }
    }
  }

  /// Saves the Excel file to a temporary directory and returns its path.
  static Future<String> _saveFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Opens the saved file with the system's default app.
  static Future<void> _openFile(String filePath) async {
    await OpenFile.open(filePath);
  }
}
