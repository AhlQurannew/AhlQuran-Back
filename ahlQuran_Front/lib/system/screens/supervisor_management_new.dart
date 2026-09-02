import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/supervisor.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/supervisor.dart';
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

// Supervisor Management Controller
class SupervisorManagementController extends GetxController {
  final RxList<Supervisor> supervisors = <Supervisor>[].obs;
  final RxList<Supervisor> filteredSupervisors = <Supervisor>[].obs;
  final RxList<Supervisor> selectedSupervisors = <Supervisor>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSupervisors();
  }

  Future<void> fetchSupervisors() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if ProfileController is registered
      if (!Get.isRegistered<ProfileController>()) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        isLoading.value = false;
        return;
      }

      final profileController = Get.find<ProfileController>();
      final authToken = profileController.token.value;

      if (authToken.isEmpty) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.getSupervisors),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer $authToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> supervisorsData = data['supervisors'] ?? [];

        supervisors.value = supervisorsData.map((supervisorData) {
          return Supervisor.fromJson(supervisorData);
        }).toList();

        filteredSupervisors.value = supervisors;
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
    _filterSupervisors();
  }

  void _filterSupervisors() {
    if (searchQuery.value.isEmpty) {
      filteredSupervisors.value = supervisors;
    } else {
      filteredSupervisors.value = supervisors.where((supervisor) {
        final fullName = supervisor.fullName.toLowerCase();
        final email = supervisor.email?.toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();
        return fullName.contains(query) || email.contains(query);
      }).toList();
    }
  }

  void toggleSupervisorSelection(Supervisor supervisor) {
    if (selectedSupervisors.contains(supervisor)) {
      selectedSupervisors.remove(supervisor);
    } else {
      selectedSupervisors.add(supervisor);
    }
  }

  bool isSupervisorSelected(Supervisor supervisor) {
    return selectedSupervisors.contains(supervisor);
  }

  void clearSelections() {
    selectedSupervisors.clear();
  }

  Future<bool> deleteSelectedSupervisors() async {
    try {
      errorMessage.value = '';

      if (!Get.isRegistered<ProfileController>()) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        return false;
      }

      final profileController = Get.find<ProfileController>();
      final authToken = profileController.token.value;

      if (authToken.isEmpty) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        return false;
      }

      for (var supervisor in selectedSupervisors) {
        final supervisorId = supervisor.id;
        if (supervisorId != null) {
          final response = await http.delete(
            Uri.parse(ApiEndpoints.getSupervisorById(supervisorId)),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $authToken",
            },
          );

          if (response.statusCode != 204 && response.statusCode != 200) {
            errorMessage.value = 'فشل حذف المشرف: ${response.statusCode}';
            return false;
          }
        }
      }

      selectedSupervisors.clear();
      await fetchSupervisors();
      return true;
    } catch (e) {
      errorMessage.value = 'فشل حذف المشرفين: $e';
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    await fetchSupervisors();
  }
}

// Supervisor Management Screen
class SupervisorManagementScreen
    extends GetView<SupervisorManagementController> {
  const SupervisorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sidebar is selecting "Supervisors"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(6);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "إدارة شؤون المشرفين",
        child: Column(
          children: [
            _buildHeaderBar(theme),
            const SizedBox(height: 16),
            _buildSearch(theme),
            const SizedBox(height: 16),
            _buildActionButtons(theme),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSupervisorsTable(theme),
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
            'إدارة المشرفين / الصفحة الرئيسية',
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
            onPressed: () => _showAddSupervisorDialog(),
            color: const Color(0xFFC78D20),
          ),
          const SizedBox(width: 8),
          Obx(() => _buildExportButton(
                'تعديل',
                Icons.edit_outlined,
                theme,
                onPressed: controller.selectedSupervisors.length == 1
                    ? () => _showEditSupervisorDialog(
                        controller.selectedSupervisors.first)
                    : null,
              )),
          const SizedBox(width: 8),
          Obx(() => _buildExportButton(
                'حذف',
                Icons.delete_outline,
                theme,
                onPressed: controller.selectedSupervisors.isNotEmpty
                    ? () => _showDeleteConfirmation()
                    : null,
                color: Colors.red.shade400,
              )),
          const SizedBox(width: 8),
          Obx(() => _buildActionButton(
                'تحديد الكل',
                Icons.select_all,
                theme,
                onPressed: controller.filteredSupervisors.isNotEmpty
                    ? () {
                        for (var s in controller.filteredSupervisors) {
                          if (!controller.isSupervisorSelected(s)) {
                            controller.toggleSupervisorSelection(s);
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
                onPressed: controller.selectedSupervisors.isNotEmpty
                    ? () => controller.clearSelections()
                    : null,
                color: Colors.grey.shade600,
              )),
          const Spacer(),
          _buildExportButton(
            'طباعة',
            Icons.print,
            theme,
            onPressed: () => _printSupervisorsPDF(),
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

  Widget _buildSupervisorsTable(ThemeData theme) {
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

      if (controller.filteredSupervisors.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد مشرفين',
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
        source: _SupervisorDataSource(
          supervisors: controller.filteredSupervisors,
          controller: controller,
          onViewDetails: (supervisor) => _showSupervisorDetails(supervisor),
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

  Future<void> _printSupervisorsPDF() async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Get supervisors to print
      final supervisorsToPrint = controller.filteredSupervisors;

      if (supervisorsToPrint.isEmpty) {
        showErrorSnackbar('لا يوجد مشرفين للطباعة');
        return;
      }

      // Create PDF pages (split if too many supervisors)
      const supervisorsPerPage = 20;
      final pageCount = (supervisorsToPrint.length / supervisorsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * supervisorsPerPage;
        final endIndex =
            (startIndex + supervisorsPerPage > supervisorsToPrint.length)
                ? supervisorsToPrint.length
                : startIndex + supervisorsPerPage;
        final pageSupervisors =
            supervisorsToPrint.sublist(startIndex, endIndex);

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
                      'قائمة المشرفين',
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
                      1: const pw.FlexColumnWidth(3), // Name
                      2: const pw.FlexColumnWidth(4), // Email
                      3: const pw.FlexColumnWidth(1.5), // Status
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
                          _buildPdfHeaderCell('الحالة', arabicFontBold),
                        ],
                      ),

                      // Data rows
                      ...pageSupervisors.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final supervisor = entry.value;
                        return pw.TableRow(
                          children: [
                            _buildPdfCell(index.toString(), arabicFont),
                            _buildPdfCell(
                              supervisor.fullName,
                              arabicFont,
                            ),
                            _buildPdfCell(
                              supervisor.email ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              supervisor.isActive == true ? 'نشط' : 'غير نشط',
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
                        'إجمالي المشرفين: ${supervisorsToPrint.length}',
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
        name: 'قائمة_المشرفين.pdf',
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

  void _showAddSupervisorDialog() {
    Get.dialog(
      const SupervisorDialog(dialogHeader: 'إضافة مشرف'),
      barrierDismissible: false,
    ).then((result) {
      if (result == true) {
        showSuccessSnackbar('تم إضافة المشرف بنجاح');
      }
      controller.refresh();
    });
  }

  void _showEditSupervisorDialog(Supervisor supervisor) {
    if (Get.isRegistered<GenericEditController<Supervisor>>()) {
      Get.delete<GenericEditController<Supervisor>>();
    }

    Get.put(GenericEditController<Supervisor>(
      initialmodel: supervisor,
      isEdit: true,
    ));

    Get.dialog(
      const SupervisorDialog(dialogHeader: 'تعديل بيانات المشرف'),
      barrierDismissible: false,
    ).then((result) {
      // Clean up the controller first
      if (Get.isRegistered<GenericEditController<Supervisor>>()) {
        Get.delete<GenericEditController<Supervisor>>();
      }

      if (result == true) {
        showSuccessSnackbar('تم تحديث بيانات المشرف بنجاح');
        controller.refresh();
      } else if (result == false) {
        final errorMsg = controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : 'فشل تحديث بيانات المشرف';
        showErrorSnackbar(errorMsg);
      }
      // Selection is NOT cleared - user must use cancel button to clear
    });
  }

  void _showSupervisorDetails(Supervisor supervisor) {
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
                    'بيانات المشرف ${supervisor.fullName}',
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
              _buildDetailRow('الاسم الأول:', supervisor.firstname ?? '-'),
              _buildDetailRow('الاسم الأخير:', supervisor.lastname ?? '-'),
              _buildDetailRow('البريد الإلكتروني:', supervisor.email ?? '-'),
              _buildDetailRow(
                  'الحالة:', supervisor.isActive == true ? 'نشط' : 'غير نشط'),
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
              'هل أنت متأكد من حذف ${controller.selectedSupervisors.length} مشرف؟',
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
              final success = await controller.deleteSelectedSupervisors();
              if (success) {
                showSuccessSnackbar('تم حذف المشرفين بنجاح');
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
}

// DataSource for SfDataGrid
class _SupervisorDataSource extends DataGridSource {
  final List<Supervisor> supervisors;
  final SupervisorManagementController controller;
  final Function(Supervisor) onViewDetails;

  _SupervisorDataSource({
    required this.supervisors,
    required this.controller,
    required this.onViewDetails,
  }) {
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void _buildDataGridRows() {
    dataGridRows = supervisors.map<DataGridRow>((supervisor) {
      return DataGridRow(
        cells: [
          DataGridCell<Supervisor>(columnName: 'selection', value: supervisor),
          DataGridCell<Supervisor>(columnName: 'action', value: supervisor),
          DataGridCell<String>(
            columnName: 'name',
            value: supervisor.fullName,
          ),
          DataGridCell<String>(
            columnName: 'email',
            value: supervisor.email ?? '',
          ),
          DataGridCell<String>(
            columnName: 'status',
            value: supervisor.isActive == true ? 'نشط' : 'غير نشط',
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final supervisor = row.getCells()[0].value as Supervisor;
    final isSelected = controller.isSupervisorSelected(supervisor);

    return DataGridRowAdapter(
      color: isSelected ? Colors.teal.shade50 : null,
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'selection') {
          return Center(
            child: Obx(() => Checkbox(
                  value: controller.isSupervisorSelected(supervisor),
                  onChanged: (value) {
                    controller.toggleSupervisorSelection(supervisor);
                  },
                )),
          );
        }

        if (cell.columnName == 'action') {
          return Center(
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
              tooltip: 'عرض التفاصيل',
              onPressed: () => onViewDetails(supervisor),
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
