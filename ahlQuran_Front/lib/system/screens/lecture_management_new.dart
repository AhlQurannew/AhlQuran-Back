import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/lecture_management_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/lecture_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/lecture.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/error_illustration.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/const/lecture.dart'
    as lecture_const;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'base_layout.dart';

class LectureManagementScreen extends GetView<LectureManagementController> {
  const LectureManagementScreen({super.key});

  bool get _isTeacher {
    try {
      final profileController = Get.find<ProfileController>();
      return profileController.userRole.value == 'teacher';
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure sidebar is selecting "Lectures"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(3);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });

    final theme = Theme.of(context);

    return BaseLayout(
      title: _isTeacher ? "حلقاتي" : "إدارة شؤون الحلقات",
      child: Column(
        children: [
          // Golden header bar
          _buildHeaderBar(theme),

          const SizedBox(height: 16),

          // Search and filters
          _buildSearchAndFilters(theme),

          const SizedBox(height: 16),

          // Action buttons (hidden for teachers)
          if (!_isTeacher) _buildActionButtons(theme),
          if (!_isTeacher) const SizedBox(height: 16),

          // Lectures table
          Expanded(
            child: _buildLecturesTable(theme),
          ),
        ],
      ),
    );
  }

  /// Golden header bar with title
  Widget _buildHeaderBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDEB059), // Muted gold/orange from theme
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _isTeacher
                ? 'الصفحة الرئيسية  /  حلقاتي'
                : 'الصفحة الرئيسية  /  إعدادات  /  إدارة الحلقات',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Search and filter section
  Widget _buildSearchAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'البحث...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: theme.cardColor,
        ),
        onChanged: (value) => controller.searchQuery.value = value,
      ),
    );
  }

  /// Action buttons row
  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left side - Action Buttons
          _buildActionButton(
            'إضافة',
            Icons.add,
            theme,
            onPressed: () => _showAddLectureDialog(),
            color: const Color(0xFFC78D20),
          ),
          const SizedBox(width: 8),

          Obx(() => _buildOutlinedButton(
                'تعديل',
                Icons.edit_outlined,
                theme,
                onPressed: controller.selectedLectures.length == 1
                    ? () => _showEditLectureDialog(
                        controller.selectedLectures.first)
                    : null,
              )),
          const SizedBox(width: 8),

          Obx(() => _buildOutlinedButton(
                'تكرار',
                Icons.copy,
                theme,
                onPressed: controller.selectedLectures.length == 1
                    ? () => controller
                        .duplicateLecture(controller.selectedLectures.first)
                    : null,
              )),
          const SizedBox(width: 8),

          Obx(() => _buildOutlinedButton(
                'حذف',
                Icons.delete_outline,
                theme,
                onPressed: controller.selectedLectures.isNotEmpty
                    ? () => _confirmDelete()
                    : null,
                color: Colors.red.shade400,
              )),
          const SizedBox(width: 8),

          Obx(() => _buildActionButton(
                'تحديد الكل',
                Icons.select_all,
                theme,
                onPressed: controller.filteredLectures.isNotEmpty
                    ? () => controller.selectAllLectures()
                    : null,
                color: const Color(0xFFC78D20),
              )),
          const SizedBox(width: 8),

          Obx(() => _buildOutlinedButton(
                'إلغاء',
                Icons.cancel_outlined,
                theme,
                onPressed: controller.selectedLectures.isNotEmpty
                    ? () => controller.deselectAllLectures()
                    : null,
                color: Colors.grey.shade600,
              )),

          const Spacer(),

          // Right side - Export Button
          _buildOutlinedButton(
            'طباعة',
            Icons.print,
            theme,
            onPressed: () => _printLecturesPDF(),
          ),
        ],
      ),
    );
  }

  /// Lectures data table
  Widget _buildLecturesTable(ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: ThreeBounce());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return ErrorIllustration(
          illustrationPath: 'assets/illustration/bad-connection.svg',
          title: 'خطأ في الاتصال',
          message: controller.errorMessage.value,
          onRetry: () => controller.refresh(),
        );
      }

      if (controller.filteredLectures.isEmpty) {
        return Center(
          child: Text(
            _isTeacher ? 'لا توجد حلقات مخصصة لك' : 'لا توجد حلقات',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: SfDataGrid(
          source: _LectureDataSource(
            lectures: controller.filteredLectures,
            selectedLectures: controller.selectedLectures,
            onSelectionChanged: (lecture) =>
                controller.toggleLectureSelection(lecture),
            theme: theme,
            isTeacher: _isTeacher,
          ),
          columns: _buildColumns(),
          selectionMode: SelectionMode.none,
          rowHeight: 60,
          headerRowHeight: 50,
          columnWidthMode: ColumnWidthMode.fill,
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
        ),
      );
    });
  }

  /// Build table columns
  List<GridColumn> _buildColumns() {
    return [
      // Only show select column for non-teachers
      if (!_isTeacher)
        GridColumn(
          columnName: 'select',
          width: 80,
          label: Container(
            alignment: Alignment.center,
            color: Colors.teal.shade700,
            child: const Text(
              '',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      GridColumn(
        columnName: 'name_ar',
        label: Container(
          alignment: Alignment.center,
          color: Colors.teal.shade700,
          child: const Text(
            'اسم الحلقة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      GridColumn(
        columnName: 'type',
        label: Container(
          alignment: Alignment.center,
          color: Colors.teal.shade700,
          child: const Text(
            'نوع الحلقة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      GridColumn(
        columnName: 'category',
        width: 100,
        label: Container(
          alignment: Alignment.center,
          color: Colors.teal.shade700,
          child: const Text(
            'الفئة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // Only show teachers column for non-teachers
      if (!_isTeacher)
        GridColumn(
          columnName: 'teachers',
          label: Container(
            alignment: Alignment.center,
            color: Colors.teal.shade700,
            child: const Text(
              'قائمة المعلمين',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      GridColumn(
        columnName: 'id',
        width: 80,
        label: Container(
          alignment: Alignment.center,
          color: Colors.teal.shade700,
          child: const Text(
            'عدد الطلاب',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ];
  }

  /// Build action button (filled)
  Widget _buildActionButton(
    String label,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }

  /// Build outlined button
  Widget _buildOutlinedButton(
    String label,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    final isDisabled = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDisabled ? Colors.grey.shade400 : (color ?? Colors.teal.shade700),
        side: BorderSide(
            color: isDisabled
                ? Colors.grey.shade300
                : (color ?? Colors.teal.shade700)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        disabledForegroundColor: Colors.grey.shade400,
        disabledBackgroundColor: Colors.grey.shade50,
      ),
    );
  }

  Future<void> _printLecturesPDF() async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Get lectures to print
      final lecturesToPrint = controller.filteredLectures;

      if (lecturesToPrint.isEmpty) {
        showErrorSnackbar('لا توجد حلقات للطباعة');
        return;
      }

      // Create PDF pages (split if too many lectures)
      const lecturesPerPage = 20;
      final pageCount = (lecturesToPrint.length / lecturesPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * lecturesPerPage;
        final endIndex = (startIndex + lecturesPerPage > lecturesToPrint.length)
            ? lecturesToPrint.length
            : startIndex + lecturesPerPage;
        final pageLectures = lecturesToPrint.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(
              base: arabicFont,
              bold: arabicFontBold,
            ),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#4DB6AC'),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'قائمة الحلقات',
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 20,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1), // #
                      1: const pw.FlexColumnWidth(2.5), // Name
                      2: const pw.FlexColumnWidth(2), // Type
                      3: const pw.FlexColumnWidth(1.5), // Category
                      4: const pw.FlexColumnWidth(3), // Teachers
                      5: const pw.FlexColumnWidth(1), // Student Count
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#4DB6AC'),
                        ),
                        children: [
                          _buildPdfHeaderCell('#', arabicFontBold),
                          _buildPdfHeaderCell('اسم الحلقة', arabicFontBold),
                          _buildPdfHeaderCell('نوع الحلقة', arabicFontBold),
                          _buildPdfHeaderCell('الفئة', arabicFontBold),
                          _buildPdfHeaderCell('قائمة المعلمين', arabicFontBold),
                          _buildPdfHeaderCell('عدد الطلاب', arabicFontBold),
                        ],
                      ),

                      // Data rows
                      ...pageLectures.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final lecture = entry.value;
                        return pw.TableRow(
                          children: [
                            _buildPdfCell(index.toString(), arabicFont),
                            _buildPdfCell(
                              lecture.lecture.lectureNameAr,
                              arabicFont,
                            ),
                            _buildPdfCell(
                              _getTypeText(lecture.lecture.circleType),
                              arabicFont,
                            ),
                            _buildPdfCell(
                              _getCategoryText(lecture.lecture.category),
                              arabicFont,
                            ),
                            _buildPdfCell(
                              lecture.teachers
                                  .map((t) => '${t.firstName} ${t.lastName}')
                                  .join(', '),
                              arabicFont,
                            ),
                            _buildPdfCell(
                              lecture.studentCount.toString(),
                              arabicFont,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.Spacer(),

                  // Footer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'صفحة ${pageIndex + 1} من $pageCount',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'إجمالي الحلقات: ${lecturesToPrint.length}',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'قائمة_الحلقات.pdf',
      );

      showSuccessSnackbar('تم إنشاء ملف PDF بنجاح');
    } catch (e) {
      showErrorSnackbar('خطأ في إنشاء ملف PDF: $e');
    }
  }

  pw.Widget _buildPdfHeaderCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildPdfCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  String _getCategoryText(String? category) {
    switch (category) {
      case 'male':
        return 'ذكور';
      case 'female':
        return 'إناث';
      case 'both':
        return 'ذكور و إناث';
      default:
        return '';
    }
  }

  String _getTypeText(String? type) {
    return lecture_const.getCircleTypeText(type);
  }

  /// Show dialog for adding a new lecture
  void _showAddLectureDialog() {
    // Clean up any existing controller
    _cleanupEditController();

    // Register the controller with null data for new lecture
    Get.put(GenericEditController<LectureForm>(
      initialmodel: null,
      isEdit: false,
    ));

    Get.dialog(
      const LectureDialog(),
      barrierDismissible: false,
    ).then((result) {
      // Dialog handles its own refresh, just cleanup
      _cleanupEditController();

      // Show success message AFTER dialog closes
      if (result == true) {
        showSuccessSnackbar('تم إضافة الحلقة بنجاح');
      }
    });
  }

  /// Show dialog for editing an existing lecture
  void _showEditLectureDialog(LectureForm lecture) {
    // Clean up any existing controller
    _cleanupEditController();

    // Create a deep copy of the lecture to avoid reference issues
    final lectureCopy = LectureForm(
      lecture: lecture.lecture,
      teachers: List.from(lecture.teachers),
      schedules: List.from(lecture.schedules),
      studentCount: lecture.studentCount,
    );

    // Register the controller with the copied lecture data
    Get.put(GenericEditController<LectureForm>(
      initialmodel: lectureCopy,
      isEdit: true,
    ));

    Get.dialog(
      const LectureDialog(dialogHeader: 'تعديل حلقة'),
      barrierDismissible: false,
    ).then((result) {
      // Dialog handles selection clearing and refresh internally
      _cleanupEditController();

      // Show success/error message AFTER dialog closes
      if (result == true) {
        // Success
        showSuccessSnackbar('تم تحديث الحلقة بنجاح');
      } else if (result == false) {
        // Failure
        final errorMsg = controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : 'فشل تحديث الحلقة';
        showErrorSnackbar(errorMsg);
      }
    });
  }

  /// Clean up the edit controller
  void _cleanupEditController() {
    if (Get.isRegistered<GenericEditController<LectureForm>>()) {
      Get.delete<GenericEditController<LectureForm>>();
    }
  }

  /// Confirm delete dialog
  void _confirmDelete() {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText:
          'هل أنت متأكد من حذف ${controller.selectedLectures.length} حلقة؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Navigator.of(Get.overlayContext!).pop();
        controller.deleteSelectedLectures();
      },
      onCancel: () {
        Navigator.of(Get.overlayContext!).pop();
      },
    );
  }
}

/// Data source for SfDataGrid
class _LectureDataSource extends DataGridSource {
  final List<LectureForm> lectures;
  final RxList<LectureForm> selectedLectures;
  final Function(LectureForm) onSelectionChanged;
  final ThemeData theme;
  final bool isTeacher;

  _LectureDataSource({
    required this.lectures,
    required this.selectedLectures,
    required this.onSelectionChanged,
    required this.theme,
    required this.isTeacher,
  });

  @override
  List<DataGridRow> get rows => lectures
      .map((lecture) => DataGridRow(cells: [
            // Only include select cell for non-teachers
            if (!isTeacher)
              DataGridCell<LectureForm>(columnName: 'select', value: lecture),
            DataGridCell<String>(
                columnName: 'name_ar', value: lecture.lecture.lectureNameAr),
            DataGridCell<String>(
                columnName: 'type',
                value: _getTypeText(lecture.lecture.circleType)),
            DataGridCell<String>(
                columnName: 'category',
                value: _getCategoryText(lecture.lecture.category)),
            // Only include teachers cell for non-teachers
            if (!isTeacher)
              DataGridCell<String>(
                  columnName: 'teachers',
                  value: lecture.teachers
                      .map((t) => '${t.firstName} ${t.lastName}')
                      .join(', ')),
            DataGridCell<int>(columnName: 'id', value: lecture.studentCount),
          ]))
      .toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final cells = row.getCells();

    // Build list of widgets based on what columns are visible
    List<Widget> cellWidgets = [];

    for (var cell in cells) {
      final columnName = cell.columnName;

      if (columnName == 'select') {
        // Checkbox (only for non-teachers)
        cellWidgets.add(
          Center(
            child: Obx(() {
              final lecture = cell.value as LectureForm;
              return Checkbox(
                value: selectedLectures.contains(lecture),
                onChanged: (_) => onSelectionChanged(lecture),
              );
            }),
          ),
        );
      } else if (columnName == 'name_ar') {
        // Name AR
        cellWidgets.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              cell.value as String? ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (columnName == 'type') {
        // Type
        cellWidgets.add(
          Center(
            child: Text(
              cell.value as String? ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      } else if (columnName == 'category') {
        // Category
        cellWidgets.add(
          Center(
            child: Text(
              cell.value as String? ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      } else if (columnName == 'teachers') {
        // Teachers
        cellWidgets.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              cell.value as String? ?? '',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (columnName == 'id') {
        // Student Count
        cellWidgets.add(
          Center(
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }
    }

    return DataGridRowAdapter(cells: cellWidgets);
  }

  String _getCategoryText(String? category) {
    switch (category) {
      case 'male':
        return 'ذكور';
      case 'female':
        return 'إناث';
      case 'both':
        return 'ذكور و إناث';
      default:
        return '';
    }
  }

  String _getTypeText(String? type) {
    return lecture_const.getCircleTypeText(type);
  }
}
