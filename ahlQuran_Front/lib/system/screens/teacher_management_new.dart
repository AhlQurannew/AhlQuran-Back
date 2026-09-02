import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/teacher_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/error_illustration.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'base_layout.dart';

// Teacher Management Controller
class TeacherManagementController extends GetxController {
  final RxList<TeacherInfoDialog> teachers = <TeacherInfoDialog>[].obs;
  final RxList<TeacherInfoDialog> filteredTeachers = <TeacherInfoDialog>[].obs;
  final RxList<TeacherInfoDialog> selectedTeachers = <TeacherInfoDialog>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final profileController = Get.find<ProfileController>();
      final authToken = profileController.token.value;

      if (authToken.isEmpty) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.getTeachers),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer $authToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> teachersData = data['teachers'] ?? [];

        teachers.value = teachersData.map((teacherData) {
          return TeacherInfoDialog.fromJson(teacherData);
        }).toList();

        filteredTeachers.value = teachers;
      } else if (response.statusCode == 401) {
        errorMessage.value = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
      } else {
        errorMessage.value = 'فشل تحميل البيانات: ${response.statusCode}';
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'فشل تحميل البيانات: $e';
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _filterTeachers();
  }

  void _filterTeachers() {
    if (searchQuery.value.isEmpty) {
      filteredTeachers.value = teachers;
    } else {
      filteredTeachers.value = teachers.where((teacher) {
        final fullName =
            '${teacher.firstName} ${teacher.lastName}'.toLowerCase();
        final riwaya = teacher.riwaya.toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return fullName.contains(query) || riwaya.contains(query);
      }).toList();
    }
  }

  void toggleTeacherSelection(TeacherInfoDialog teacher) {
    if (selectedTeachers.contains(teacher)) {
      selectedTeachers.remove(teacher);
    } else {
      selectedTeachers.add(teacher);
    }
  }

  bool isTeacherSelected(TeacherInfoDialog teacher) {
    return selectedTeachers.contains(teacher);
  }

  void clearSelections() {
    selectedTeachers.clear();
  }

  Future<bool> deleteSelectedTeachers() async {
    try {
      // Clear any previous error messages
      errorMessage.value = '';

      final profileController = Get.find<ProfileController>();
      final authToken = profileController.token.value;

      if (authToken.isEmpty) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        return false;
      }

      for (var teacher in selectedTeachers) {
        final teacherId = teacher.teacherId;
        if (teacherId != null) {
          final response = await http.delete(
            Uri.parse(ApiEndpoints.getTeacherById(teacherId)),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $authToken",
            },
          );

          if (response.statusCode != 204 && response.statusCode != 200) {
            errorMessage.value = 'فشل حذف المعلم: ${response.statusCode}';
            return false;
          }
        }
      }

      selectedTeachers.clear();
      await fetchTeachers();
      return true;
    } catch (e) {
      errorMessage.value = 'فشل حذف المعلمين: $e';
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    await fetchTeachers();
  }
}

class TeacherManagementScreen extends GetView<TeacherManagementController> {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sidebar is selecting "Teachers"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(5);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "إدارة شؤون المعلمين",
        child: Column(
          children: [
            _buildHeaderBar(theme),
            const SizedBox(height: 16),
            _buildSearch(theme),
            const SizedBox(height: 16),
            _buildActionButtons(theme),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTeachersTable(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDEB059),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'إدارة المعلمين / الصفحة الرئيسية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ThemeData theme) {
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
        onChanged: (value) => controller.updateSearchQuery(value),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionButton(
            'إضافة',
            Icons.add,
            theme,
            onPressed: () => _showAddTeacherDialog(),
            color: const Color(0xFFC78D20),
          ),
          const SizedBox(width: 8),
          Obx(() => _buildExportButton(
                'تعديل',
                Icons.edit_outlined,
                theme,
                onPressed: controller.selectedTeachers.length == 1
                    ? () => _showEditTeacherDialog(
                        controller.selectedTeachers.first)
                    : null,
              )),
          const SizedBox(width: 8),
          Obx(() => _buildExportButton(
                'حذف',
                Icons.delete_outline,
                theme,
                onPressed: controller.selectedTeachers.isNotEmpty
                    ? () => _showDeleteConfirmation()
                    : null,
                color: Colors.red.shade400,
              )),
          const SizedBox(width: 8),
          Obx(() => _buildActionButton(
                'تحديد الكل',
                Icons.select_all,
                theme,
                onPressed: controller.filteredTeachers.isNotEmpty
                    ? () {
                        for (var t in controller.filteredTeachers) {
                          if (!controller.isTeacherSelected(t)) {
                            controller.toggleTeacherSelection(t);
                          }
                        }
                      }
                    : null,
                color: const Color(0xFFC78D20),
              )),
          const SizedBox(width: 8),
          Obx(() => _buildExportButton(
                'إلغاء',
                Icons.cancel_outlined,
                theme,
                onPressed: controller.selectedTeachers.isNotEmpty
                    ? () => controller.clearSelections()
                    : null,
                color: Colors.grey.shade600,
              )),
          const Spacer(),
          _buildExportButton(
            'طباعة',
            Icons.print,
            theme,
            onPressed: () => _printTeachersPDF(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String text, IconData icon, ThemeData theme,
      {Color? color, VoidCallback? onPressed}) {
    final isDisabled = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
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

  Widget _buildActionButton(
    String text,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildTeachersTable(ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: ThreeBounce());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return ErrorIllustration(
          illustrationPath: 'assets/illustration/bad-connection.svg',
          title: 'خطأ في الاتصال',
          message: controller.errorMessage.value,
          onRetry: () => controller.refresh(),
        );
      }

      if (controller.filteredTeachers.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد معلمين',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      return _buildDataGrid(theme);
    });
  }

  Widget _buildDataGrid(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SfDataGrid(
        source: _TeacherDataSource(
          teachers: controller.filteredTeachers,
          controller: controller,
          onViewDetails: (teacher) => _showTeacherDetails(teacher),
        ),
        columns: _buildColumns(),
        columnWidthMode: ColumnWidthMode.fill,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        selectionMode: SelectionMode.multiple,
        checkboxColumnSettings: const DataGridCheckboxColumnSettings(
          showCheckboxOnHeader: true,
        ),
        rowHeight: 60,
        headerRowHeight: 50,
      ),
    );
  }

  List<GridColumn> _buildColumns() {
    return [
      GridColumn(
        columnName: 'selection',
        width: 60,
        label: Container(
          alignment: Alignment.center,
          color: Colors.teal.shade700,
          child: const Icon(Icons.check_box_outline_blank, color: Colors.white),
        ),
      ),
      GridColumn(
        columnName: 'action',
        width: 80,
        label: _buildHeaderCell(''),
      ),
      GridColumn(
        columnName: 'name',
        label: _buildHeaderCell('الاسم'),
      ),
      GridColumn(
        columnName: 'email',
        label: _buildHeaderCell('البريد الإلكتروني'),
      ),
      GridColumn(
        columnName: 'riwaya',
        width: 150,
        label: _buildHeaderCell('الرواية'),
      ),
      GridColumn(
        columnName: 'hire_date',
        width: 150,
        label: _buildHeaderCell('تاريخ التعيين'),
      ),
      GridColumn(
        columnName: 'status',
        width: 100,
        label: _buildHeaderCell('الحالة'),
      ),
    ];
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      color: Colors.teal.shade700,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showAddTeacherDialog() {
    Get.dialog(
      const TeacherDialog(dialogHeader: 'إضافة معلم'),
      barrierDismissible: false,
    ).then((result) {
      if (result == true) {
        showSuccessSnackbar('تم إضافة المعلم بنجاح');
      }
      controller.refresh();
    });
  }

  void _showEditTeacherDialog(TeacherInfoDialog teacher) {
    // Clean up any existing controller
    if (Get.isRegistered<GenericEditController<TeacherInfoDialog>>()) {
      Get.delete<GenericEditController<TeacherInfoDialog>>();
    }

    // Register the controller with the teacher data
    Get.put(GenericEditController<TeacherInfoDialog>(
      initialmodel: teacher,
      isEdit: true,
    ));

    // Show the dialog
    Get.dialog(
      const TeacherDialog(dialogHeader: 'تعديل بيانات المعلم'),
      barrierDismissible: false,
    ).then((result) {
      // Clean up the controller first
      if (Get.isRegistered<GenericEditController<TeacherInfoDialog>>()) {
        Get.delete<GenericEditController<TeacherInfoDialog>>();
      }

      if (result == true) {
        // Refresh the teacher list
        controller.fetchTeachers();

        // Show success snackbar
        showSuccessSnackbar('تم تحديث بيانات المعلم بنجاح');
      }

      // Clear selection after edit dialog closes (whether saved or cancelled)
      controller.clearSelections();
    });
  }

  void _showTeacherDetails(TeacherInfoDialog teacher) {
    Get.dialog(
      Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'بيانات المعلم ${teacher.firstName} ${teacher.lastName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('الاسم:', teacher.firstName),
              _buildDetailRow('اسم العائلة:', teacher.lastName),
              _buildDetailRow('البريد الإلكتروني:', teacher.email),
              _buildDetailRow('الرواية:', teacher.riwaya),
              _buildDetailRow('تاريخ التعيين:', teacher.hireDate ?? '-'),
              _buildDetailRow('الحالة:', teacher.isActive ? 'نشط' : 'غير نشط'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.right,
        ),
        content: Obx(() => Text(
              'هل أنت متأكد من حذف ${controller.selectedTeachers.length} معلم؟',
              textAlign: TextAlign.right,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(Get.overlayContext!).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(Get.overlayContext!).pop();
              final success = await controller.deleteSelectedTeachers();
              if (success) {
                showSuccessSnackbar('تم حذف المعلمين بنجاح');
              } else {
                showErrorSnackbar(controller.errorMessage.value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _printTeachersPDF() async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Get teachers to print
      final teachersToPrint = controller.filteredTeachers;

      if (teachersToPrint.isEmpty) {
        showErrorSnackbar('لا يوجد معلمين للطباعة');
        return;
      }

      // Create PDF pages (split if too many teachers)
      const teachersPerPage = 20;
      final pageCount = (teachersToPrint.length / teachersPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * teachersPerPage;
        final endIndex = (startIndex + teachersPerPage > teachersToPrint.length)
            ? teachersToPrint.length
            : startIndex + teachersPerPage;
        final pageTeachers = teachersToPrint.sublist(startIndex, endIndex);

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
                      'قائمة المعلمين',
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
                      2: const pw.FlexColumnWidth(3), // Email
                      3: const pw.FlexColumnWidth(2), // Riwaya
                      4: const pw.FlexColumnWidth(1.5), // Hire Date
                      5: const pw.FlexColumnWidth(1), // Status
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#4DB6AC'),
                        ),
                        children: [
                          _buildPdfHeaderCell('#', arabicFontBold),
                          _buildPdfHeaderCell('الاسم', arabicFontBold),
                          _buildPdfHeaderCell(
                              'البريد الإلكتروني', arabicFontBold),
                          _buildPdfHeaderCell('الرواية', arabicFontBold),
                          _buildPdfHeaderCell('تاريخ التعيين', arabicFontBold),
                          _buildPdfHeaderCell('الحالة', arabicFontBold),
                        ],
                      ),

                      // Data rows
                      ...pageTeachers.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final teacher = entry.value;
                        return pw.TableRow(
                          children: [
                            _buildPdfCell(index.toString(), arabicFont),
                            _buildPdfCell(
                              '${teacher.firstName} ${teacher.lastName}',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              teacher.email,
                              arabicFont,
                            ),
                            _buildPdfCell(
                              teacher.riwaya,
                              arabicFont,
                            ),
                            _buildPdfCell(
                              teacher.hireDate?.substring(0, 10) ?? '-',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              teacher.isActive ? 'نشط' : 'غير نشط',
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
                        'إجمالي المعلمين: ${teachersToPrint.length}',
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
        name: 'قائمة_المعلمين.pdf',
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
}

// DataSource for SfDataGrid
class _TeacherDataSource extends DataGridSource {
  final List<TeacherInfoDialog> teachers;
  final TeacherManagementController controller;
  final Function(TeacherInfoDialog) onViewDetails;

  _TeacherDataSource({
    required this.teachers,
    required this.controller,
    required this.onViewDetails,
  }) {
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void _buildDataGridRows() {
    dataGridRows = teachers.map<DataGridRow>((teacher) {
      return DataGridRow(
        cells: [
          DataGridCell<TeacherInfoDialog>(
              columnName: 'selection', value: teacher),
          DataGridCell<TeacherInfoDialog>(columnName: 'action', value: teacher),
          DataGridCell<String>(
            columnName: 'name',
            value: '${teacher.firstName} ${teacher.lastName}',
          ),
          DataGridCell<String>(
            columnName: 'email',
            value: teacher.email,
          ),
          DataGridCell<String>(
            columnName: 'riwaya',
            value: teacher.riwaya,
          ),
          DataGridCell<String>(
            columnName: 'hire_date',
            value: teacher.hireDate?.substring(0, 10) ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'status',
            value: teacher.isActive ? 'نشط' : 'غير نشط',
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final teacher = row.getCells()[0].value as TeacherInfoDialog;
    final isSelected = controller.isTeacherSelected(teacher);

    return DataGridRowAdapter(
      color: isSelected ? Colors.teal.shade50 : null,
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'selection') {
          return Center(
            child: Obx(() => Checkbox(
                  value: controller.isTeacherSelected(teacher),
                  onChanged: (value) {
                    controller.toggleTeacherSelection(teacher);
                  },
                )),
          );
        }

        if (cell.columnName == 'action') {
          return Center(
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
              tooltip: 'عرض التفاصيل',
              onPressed: () => onViewDetails(teacher),
            ),
          );
        }

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}
