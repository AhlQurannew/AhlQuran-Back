import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/guardian_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/guardian.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/error_illustration.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/custom_snackbar.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'base_layout.dart';

// Guardian Management Controller
class GuardianManagementController extends GetxController {
  final RxList<GuardianInfoDialog> guardians = <GuardianInfoDialog>[].obs;
  final RxList<GuardianInfoDialog> filteredGuardians =
      <GuardianInfoDialog>[].obs;
  final RxList<GuardianInfoDialog> selectedGuardians =
      <GuardianInfoDialog>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchGuardians();
  }

  Future<void> fetchGuardians() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Fetch guardians using ApiService which handles token refresh automatically
      final data = await ApiService.fetchObject<Map<String, dynamic>>(
        ApiEndpoints.getGuardians,
        (json) => json,
      );

      final List<dynamic> guardiansData = data['guardians'] ?? [];

      guardians.value = guardiansData.map((guardianData) {
        // Parse student info if available
        List<Map<String, dynamic>> children = [];
        if (guardianData['student'] != null) {
          final studentData = guardianData['student'];
          children = [
            {
              'student_id': studentData['id'],
              'first_name_ar': studentData['first_name_ar'],
              'last_name_ar': studentData['last_name_ar'],
            }
          ];
        }

        // Convert backend response to GuardianInfoDialog
        return GuardianInfoDialog.fromJson({
          'info': {
            'guardian_id': guardianData['id'],
            'first_name': guardianData['first_name'],
            'last_name': guardianData['last_name'],
            'relationship': guardianData['relationship_to_student'],
            'date_of_birth': guardianData['date_of_birth'],
            'job': guardianData['job'],
            'home_address': guardianData['address'],
          },
          'contact_info': {
            'email': guardianData['email'],
            'phone_number': guardianData['phone_number'],
          },
          'account_info': {
            'account_id': guardianData['user_id'],
            'username': guardianData['username'],
          },
          'children': children,
          'student_id': guardianData['student_id'],
        });
      }).toList();

      filteredGuardians.value = guardians;
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'فشل تحميل البيانات: $e';
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _filterGuardians();
  }

  void _filterGuardians() {
    if (searchQuery.value.isEmpty) {
      filteredGuardians.value = guardians;
    } else {
      filteredGuardians.value = guardians.where((guardian) {
        final fullName =
            '${guardian.guardian.firstName} ${guardian.guardian.lastName}'
                .toLowerCase();
        final relationship =
            guardian.guardian.relationship?.toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();
        return fullName.contains(query) || relationship.contains(query);
      }).toList();
    }
  }

  void toggleGuardianSelection(GuardianInfoDialog guardian) {
    if (selectedGuardians.contains(guardian)) {
      selectedGuardians.remove(guardian);
    } else {
      selectedGuardians.add(guardian);
    }
  }

  bool isGuardianSelected(GuardianInfoDialog guardian) {
    return selectedGuardians.contains(guardian);
  }

  void clearSelections() {
    selectedGuardians.clear();
  }

  Future<bool> deleteSelectedGuardians() async {
    try {
      // Clear any previous error messages
      errorMessage.value = '';

      // Delete each selected guardian via API using ApiService
      for (var guardian in selectedGuardians) {
        final guardianId = guardian.guardian.guardianId;
        if (guardianId != null) {
          await ApiService.delete(ApiEndpoints.getGuardianById(guardianId));
        }
      }

      // Refresh the list after deletion
      selectedGuardians.clear();
      await fetchGuardians();
      return true;
    } catch (e) {
      errorMessage.value = 'فشل حذف الأوصياء: $e';
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    await fetchGuardians();
  }
}

class GuardianManagementScreen extends GetView<GuardianManagementController> {
  const GuardianManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sidebar is selecting "Guardians"
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
        title: "إدارة شؤون الأوصياء",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Search
            _buildSearch(theme),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(theme),

            const SizedBox(height: 16),

            // Guardians table
            Expanded(
              child: _buildGuardiansTable(theme),
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
            'إدارة الأوصياء / الصفحة الرئيسية',
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
          // Add
          _buildActionButton(
            'إضافة',
            Icons.add,
            theme,
            onPressed: () => _showAddGuardianDialog(),
            color: const Color(0xFFC78D20),
          ),
          const SizedBox(width: 8),

          // Edit - Only enabled when exactly ONE guardian is selected
          Obx(() => _buildExportButton(
                'تعديل',
                Icons.edit_outlined,
                theme,
                onPressed: controller.selectedGuardians.length != 1
                    ? null
                    : () => _showEditGuardianDialog(
                        controller.selectedGuardians.first),
              )),
          const SizedBox(width: 8),

          // Delete
          Obx(() => _buildExportButton(
                'حذف',
                Icons.delete_outline,
                theme,
                onPressed: controller.selectedGuardians.isNotEmpty
                    ? () => _showDeleteConfirmation()
                    : null,
                color: Colors.red.shade400,
              )),
          const SizedBox(width: 8),

          // Select All
          Obx(() => _buildActionButton(
                'تحديد الكل',
                Icons.select_all,
                theme,
                onPressed: controller.filteredGuardians.isNotEmpty
                    ? () {
                        for (var g in controller.filteredGuardians) {
                          if (!controller.isGuardianSelected(g)) {
                            controller.toggleGuardianSelection(g);
                          }
                        }
                      }
                    : null,
                color: const Color(0xFFC78D20),
              )),
          const SizedBox(width: 8),

          // Cancel
          Obx(() => _buildExportButton(
                'إلغاء',
                Icons.cancel_outlined,
                theme,
                onPressed: controller.selectedGuardians.isNotEmpty
                    ? () => controller.clearSelections()
                    : null,
                color: Colors.grey.shade600,
              )),

          const Spacer(),

          // Print button
          _buildExportButton(
            'طباعة',
            Icons.print,
            theme,
            onPressed: () => _printGuardiansPDF(),
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

  Widget _buildGuardiansTable(ThemeData theme) {
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

      if (controller.filteredGuardians.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد أوصياء',
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
        source: _GuardianDataSource(
          guardians: controller.filteredGuardians,
          controller: controller,
          onViewDetails: (guardian) => _showGuardianDetails(guardian),
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
        columnName: 'relationship',
        width: 120,
        label: _buildHeaderCell('العلاقة'),
      ),
      GridColumn(
        columnName: 'student',
        width: 150,
        label: _buildHeaderCell('الطالب'),
      ),
      GridColumn(
        columnName: 'phone',
        width: 140,
        label: _buildHeaderCell('رقم الهاتف'),
      ),
      GridColumn(
        columnName: 'email',
        label: _buildHeaderCell('البريد الإلكتروني'),
      ),
      GridColumn(
        columnName: 'dob',
        width: 120,
        label: _buildHeaderCell('تاريخ الميلاد'),
      ),
      GridColumn(
        columnName: 'job',
        width: 120,
        label: _buildHeaderCell('الوظيفة'),
      ),
      GridColumn(
        columnName: 'address',
        label: _buildHeaderCell('العنوان'),
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

  Future<void> _printGuardiansPDF() async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Get guardians to print
      final guardiansToPrint = controller.filteredGuardians;

      if (guardiansToPrint.isEmpty) {
        showErrorSnackbar('لا يوجد أوصياء للطباعة');
        return;
      }

      // Create PDF pages (split if too many guardians)
      const guardiansPerPage = 15;
      final pageCount = (guardiansToPrint.length / guardiansPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * guardiansPerPage;
        final endIndex =
            (startIndex + guardiansPerPage > guardiansToPrint.length)
                ? guardiansToPrint.length
                : startIndex + guardiansPerPage;
        final pageGuardians = guardiansToPrint.sublist(startIndex, endIndex);

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
                      'قائمة الأوصياء',
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
                      0: const pw.FlexColumnWidth(0.8), // #
                      1: const pw.FlexColumnWidth(2), // Name
                      2: const pw.FlexColumnWidth(1.5), // Relationship
                      3: const pw.FlexColumnWidth(2), // Student
                      4: const pw.FlexColumnWidth(1.8), // Phone
                      5: const pw.FlexColumnWidth(2.5), // Email
                      6: const pw.FlexColumnWidth(1.5), // Job
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
                          _buildPdfHeaderCell('العلاقة', arabicFontBold),
                          _buildPdfHeaderCell('الطالب', arabicFontBold),
                          _buildPdfHeaderCell('رقم الهاتف', arabicFontBold),
                          _buildPdfHeaderCell(
                              'البريد الإلكتروني', arabicFontBold),
                          _buildPdfHeaderCell('الوظيفة', arabicFontBold),
                        ],
                      ),

                      // Data rows
                      ...pageGuardians.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final guardian = entry.value;

                        // Get student name
                        String studentName = '-';
                        if (guardian.children.isNotEmpty) {
                          final student = guardian.children.first;
                          studentName =
                              '${student.firstNameAr ?? ''} ${student.lastNameAr ?? ''}'
                                  .trim();
                          if (studentName.isEmpty) studentName = '-';
                        }

                        return pw.TableRow(
                          children: [
                            _buildPdfCell(index.toString(), arabicFont),
                            _buildPdfCell(
                              '${guardian.guardian.firstName ?? ''} ${guardian.guardian.lastName ?? ''}',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              guardian.guardian.relationship ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              studentName,
                              arabicFont,
                            ),
                            _buildPdfCell(
                              guardian.contactInfo.phoneNumber ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              guardian.contactInfo.email ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              guardian.guardian.job ?? '',
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
                        'إجمالي الأوصياء: ${guardiansToPrint.length}',
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
        name: 'قائمة_الأوصياء.pdf',
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

  void _showAddGuardianDialog() {
    Get.dialog(
      const GuardianDialog(dialogHeader: 'إضافة وصي'),
      barrierDismissible: false,
    ).then((result) {
      if (result == true) {
        showSuccessSnackbar('تم إضافة الوصي بنجاح');
      }
      controller.refresh();
    });
  }

  void _showEditGuardianDialog(GuardianInfoDialog guardian) {
    if (Get.isRegistered<GenericEditController<GuardianInfoDialog>>()) {
      Get.delete<GenericEditController<GuardianInfoDialog>>();
    }

    Get.put(GenericEditController<GuardianInfoDialog>(
      initialmodel: guardian,
      isEdit: true,
    ));

    Get.dialog(
      const GuardianDialog(dialogHeader: 'تعديل بيانات الوصي'),
      barrierDismissible: false,
    ).then((result) {
      // Clean up the controller first
      if (Get.isRegistered<GenericEditController<GuardianInfoDialog>>()) {
        Get.delete<GenericEditController<GuardianInfoDialog>>();
      }

      if (result == true) {
        showSuccessSnackbar('تم تحديث بيانات الوصي بنجاح');
        controller.refresh();
      } else if (result == false) {
        final errorMsg = controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : 'فشل تحديث بيانات الوصي';
        showErrorSnackbar(errorMsg);
      }
      // Selection is NOT cleared - user must use cancel button to clear
    });
  }

  void _showGuardianDetails(GuardianInfoDialog guardian) {
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
                    'بيانات الوصي ${guardian.guardian.firstName ?? ''} ${guardian.guardian.lastName ?? ''}',
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
              _buildDetailRow('الاسم:', '${guardian.guardian.firstName ?? ''}'),
              _buildDetailRow(
                  'اسم العائلة:', '${guardian.guardian.lastName ?? ''}'),
              _buildDetailRow(
                  'العلاقة:', '${guardian.guardian.relationship ?? ''}'),
              if (guardian.children.isNotEmpty)
                _buildDetailRow(
                  'الطالب:',
                  '${guardian.children.first.firstNameAr ?? ''} ${guardian.children.first.lastNameAr ?? ''}'
                      .trim(),
                ),
              _buildDetailRow(
                  'رقم الهاتف:', '${guardian.contactInfo.phoneNumber ?? ''}'),
              _buildDetailRow(
                  'البريد الإلكتروني:', '${guardian.contactInfo.email ?? ''}'),
              _buildDetailRow(
                  'تاريخ الميلاد:', '${guardian.guardian.dateOfBirth ?? ''}'),
              _buildDetailRow('الوظيفة:', '${guardian.guardian.job ?? ''}'),
              _buildDetailRow(
                  'العنوان:', '${guardian.guardian.homeAddress ?? ''}'),
              _buildDetailRow(
                  'اسم المستخدم:', '${guardian.accountInfo.username ?? ''}'),
              _buildDetailRow(
                  'كلمة المرور:', '${guardian.accountInfo.passcode ?? ''}'),
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
          // Arabic label on the left
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(width: 16),
          // Value on the right
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
              'هل أنت متأكد من حذف ${controller.selectedGuardians.length} وصي؟',
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
              final success = await controller.deleteSelectedGuardians();
              // Show snackbar after deletion completes
              Future.delayed(const Duration(milliseconds: 100), () {
                final context = Get.context;
                if (context != null) {
                  if (success) {
                    CustomSnackbar.showSuccess(
                        context, 'تم حذف الأوصياء بنجاح');
                  } else {
                    CustomSnackbar.showError(
                        context, controller.errorMessage.value);
                  }
                }
              });
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
class _GuardianDataSource extends DataGridSource {
  final List<GuardianInfoDialog> guardians;
  final GuardianManagementController controller;
  final Function(GuardianInfoDialog) onViewDetails;

  _GuardianDataSource({
    required this.guardians,
    required this.controller,
    required this.onViewDetails,
  }) {
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void _buildDataGridRows() {
    dataGridRows = guardians.map<DataGridRow>((guardian) {
      // Get student name from children list if available
      String studentName = '-';
      if (guardian.children.isNotEmpty) {
        final student = guardian.children.first;
        studentName =
            '${student.firstNameAr ?? ''} ${student.lastNameAr ?? ''}'.trim();
        if (studentName.isEmpty) studentName = '-';
      }

      return DataGridRow(
        cells: [
          DataGridCell<GuardianInfoDialog>(
              columnName: 'selection', value: guardian),
          DataGridCell<GuardianInfoDialog>(
              columnName: 'action', value: guardian),
          DataGridCell<String>(
            columnName: 'name',
            value:
                '${guardian.guardian.firstName ?? ''} ${guardian.guardian.lastName ?? ''}',
          ),
          DataGridCell<String>(
            columnName: 'relationship',
            value: guardian.guardian.relationship ?? '',
          ),
          DataGridCell<String>(
            columnName: 'student',
            value: studentName,
          ),
          DataGridCell<String>(
            columnName: 'phone',
            value: guardian.contactInfo.phoneNumber ?? '',
          ),
          DataGridCell<String>(
            columnName: 'email',
            value: guardian.contactInfo.email ?? '',
          ),
          DataGridCell<String>(
            columnName: 'dob',
            value: guardian.guardian.dateOfBirth ?? '',
          ),
          DataGridCell<String>(
            columnName: 'job',
            value: guardian.guardian.job ?? '',
          ),
          DataGridCell<String>(
            columnName: 'address',
            value: guardian.guardian.homeAddress ?? '',
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final guardian = row.getCells()[0].value as GuardianInfoDialog;
    final isSelected = controller.isGuardianSelected(guardian);

    return DataGridRowAdapter(
      color: isSelected ? Colors.teal.shade50 : null,
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'selection') {
          return Center(
            child: Obx(() => Checkbox(
                  value: controller.isGuardianSelected(guardian),
                  onChanged: (value) {
                    controller.toggleGuardianSelection(guardian);
                  },
                )),
          );
        }

        if (cell.columnName == 'action') {
          return Center(
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
              tooltip: 'عرض التفاصيل',
              onPressed: () => onViewDetails(guardian),
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
