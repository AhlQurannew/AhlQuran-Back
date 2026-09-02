import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/student_management_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/student.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/error_illustration.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/drawer_controller.dart'
    as drawer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'base_layout.dart';

class StudentManagementScreen extends GetView<StudentManagementController> {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sidebar is selecting "Students"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(4);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "إدارة شؤون الطلاب",
        child: Column(
          children: [
            // Golden header bar
            _buildHeaderBar(theme),

            const SizedBox(height: 16),

            // Search and filters
            _buildSearchAndFilters(theme),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(theme),

            const SizedBox(height: 16),

            // Students table
            Expanded(
              child: _buildStudentsTable(theme),
            ),
          ],
        ),
      ),
    );
  }

  /// Golden header bar with title
  Widget _buildHeaderBar(ThemeData theme) {
    return Obx(() => Container(
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
                controller.isReadOnly.value
                    ? 'طلابي / عرض فقط' // My Students / View Only
                    : 'إدارة الطلاب / الصفحة الرئيسية',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ));
  }

  /// Search section
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
        onChanged: (value) => controller.updateSearchQuery(value),
      ),
    );
  }

  /// Action buttons row
  Widget _buildActionButtons(ThemeData theme) {
    return Obx(() {
      // Hide action buttons for teachers (read-only mode)
      if (controller.isReadOnly.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Right Side (Start) - Action Buttons

            // Add (Filled)
            _buildActionButton(
              'إضافة',
              Icons.add,
              theme,
              onPressed: () => _showAddStudentDialog(),
              color: const Color(0xFFC78D20), // Primary theme color
            ),
            const SizedBox(width: 8),

            // Edit (Outlined) - Only enabled when exactly ONE student is selected
            Obx(() => _buildExportButton(
                  'تعديل',
                  Icons.edit_outlined,
                  theme,
                  onPressed: controller.selectedStudents.length == 1
                      ? () => _showEditStudentDialog(
                          controller.selectedStudents.first)
                      : null,
                )),
            const SizedBox(width: 8),

            // Delete (Outlined)
            Obx(() => _buildExportButton(
                  'حذف',
                  Icons.delete_outline,
                  theme,
                  onPressed: controller.selectedStudents.isNotEmpty
                      ? () => _showDeleteConfirmation()
                      : null,
                  color: Colors.red.shade400, // Red outline/text
                )),
            const SizedBox(width: 8),

            // Select All (Filled)
            _buildActionButton(
              'تحديد الكل',
              Icons.select_all,
              theme,
              onPressed: () {
                // controller.selectAll(); // TODO: Implement in controller
                // For now, select all loaded students
                for (var s in controller.filteredStudents) {
                  if (!controller.isStudentSelected(s)) {
                    controller.toggleStudentSelection(s);
                  }
                }
              },
              color: const Color(0xFFC78D20), // Primary theme color
            ),
            const SizedBox(width: 8),

            // Cancel (Outlined)
            Obx(() => _buildExportButton(
                  'إلغاء',
                  Icons.cancel_outlined,
                  theme,
                  onPressed: controller.selectedStudents.isNotEmpty
                      ? () => controller.clearSelections()
                      : null,
                  color: Colors.grey.shade600,
                )),

            const Spacer(),

            // Left Side (End) - Export Buttons

            // Print
            _buildExportButton(
              'طباعة',
              Icons.print,
              theme,
              onPressed: () => _printStudentsPDF(),
            ),
          ],
        ),
      );
    });
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

  /// Students data table
  Widget _buildStudentsTable(ThemeData theme) {
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

      if (controller.filteredStudents.isEmpty) {
        return const Center(
          child: Text(
            'لا يوجد طلاب',
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
      child: Obx(() => SfDataGrid(
            source: _StudentDataSource(
              students: controller.filteredStudents,
              controller: controller,
              onViewDetails: (student) => _showStudentDetails(student),
              isReadOnly: controller.isReadOnly.value,
            ),
            columns: _buildColumns(),
            columnWidthMode: ColumnWidthMode.fill,
            gridLinesVisibility: GridLinesVisibility.both,
            headerGridLinesVisibility: GridLinesVisibility.both,
            selectionMode: controller.isReadOnly.value
                ? SelectionMode.none
                : SelectionMode.multiple,
            checkboxColumnSettings: const DataGridCheckboxColumnSettings(
              showCheckboxOnHeader: true,
            ),
            onSelectionChanged: (addedRows, removedRows) {
              // Handle selection changes if needed
            },
            rowHeight: 60,
            headerRowHeight: 50,
          )),
    );
  }

  List<GridColumn> _buildColumns() {
    final columns = <GridColumn>[];

    // Only show selection checkbox column if not in read-only mode
    if (!controller.isReadOnly.value) {
      columns.add(
        GridColumn(
          columnName: 'selection',
          width: 60,
          label: Container(
            alignment: Alignment.center,
            color: Colors.teal.shade700,
            child:
                const Icon(Icons.check_box_outline_blank, color: Colors.white),
          ),
        ),
      );
    }

    // Action button column
    columns.addAll([
      GridColumn(
        columnName: 'action',
        width: 80,
        label: _buildHeaderCell(''), // Empty label for action column
      ),
      GridColumn(
        columnName: 'name',
        label: _buildHeaderCell('الاسم'),
      ),
      GridColumn(
        columnName: 'nickname', // Changed from 'sex'
        width: 100,
        label: _buildHeaderCell('الكنية'),
      ),
      GridColumn(
        columnName: 'gender',
        width: 100,
        label: _buildHeaderCell('الجنس'),
      ),
      GridColumn(
        columnName: 'lectures',
        label: _buildHeaderCell('الحلقات'),
      ),
      GridColumn(
        columnName: 'username',
        label: _buildHeaderCell('اسم المستخدم'),
      ),
      GridColumn(
        columnName: 'dob',
        width: 120,
        label: _buildHeaderCell('تاريخ الميلاد'),
      ),
      GridColumn(
        columnName: 'birthplace',
        label: _buildHeaderCell('مكان الميلاد'),
      ),
      GridColumn(
        columnName: 'nationality',
        width: 120,
        label: _buildHeaderCell('الجنسية'),
      ),
      GridColumn(
        columnName: 'id_type',
        width: 100,
        label: _buildHeaderCell('نوع الهوية'),
      ),
    ]);

    return columns;
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

  void _showAddStudentDialog() async {
    final result = await Get.dialog(
      const StudentDialog(dialogHeader: 'إضافة طالب'),
      barrierDismissible: false,
    );

    if (result == true) {
      // Refresh the student list
      controller.fetchAllStudents();

      // Show success snackbar (helper will handle timing)
      showSuccessSnackbar('تم إضافة الطالب بنجاح');
    }
  }

  void _showEditStudentDialog(Student student) {
    // Clean up any existing controller
    if (Get.isRegistered<GenericEditController<Student>>()) {
      Get.delete<GenericEditController<Student>>();
    }

    // Register the controller with the student data
    Get.put(GenericEditController<Student>(
      initialmodel: student,
      isEdit: true,
    ));

    // Show the dialog
    Get.dialog(
      const StudentDialog(dialogHeader: 'تعديل بيانات الطالب'),
      barrierDismissible: false,
    ).then((result) {
      // Clean up the controller first
      if (Get.isRegistered<GenericEditController<Student>>()) {
        Get.delete<GenericEditController<Student>>();
      }

      if (result == true) {
        // Refresh the student list
        controller.fetchAllStudents();

        // Show success snackbar (helper will handle timing)
        showSuccessSnackbar('تم تحديث بيانات الطالب بنجاح');
      }

      // Clear selection after edit dialog closes (whether saved or cancelled)
      controller.clearSelections();
    });
  }

  void _showStudentDetails(Student student) {
    Get.dialog(
      Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(Get.overlayContext!).pop();
                    },
                  ),
                  Text(
                    'بيانات الطالب ${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Student image
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 24),

              // Student details
              _buildDetailRow(
                  'الاسم:', '${student.personalInfo.firstNameAr ?? ''}'),
              _buildDetailRow(
                  'الكنية:', '${student.personalInfo.lastNameAr ?? ''}'),
              _buildDetailRow('الجنس:', '${student.personalInfo.sex ?? ''}'),
              _buildDetailRow('الحلقات:',
                  student.lectures.map((l) => l.lectureNameAr).join(', ')),
              _buildDetailRow(
                  'اسم المستخدم:', '${student.accountInfo.username ?? ''}'),
              _buildDetailRow('تاريخ الميلاد:',
                  '${student.personalInfo.dateOfBirth ?? ''}'),
              _buildDetailRow('مكان الميلاد:',
                  '${student.personalInfo.placeOfBirth ?? ''}'),
              _buildDetailRow(
                  'الجنسية:', '${student.personalInfo.nationality ?? ''}'),
              _buildDetailRow('نوع الهوية:',
                  student.personalInfo.sex == 'ذكر' ? 'ذكر' : 'أنثى'),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
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
              'هل أنت متأكد من حذف ${controller.selectedStudents.length} طالب؟',
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
              final success = await controller.deleteSelectedStudents();
              if (success) {
                showSuccessSnackbar('تم حذف الطلاب بنجاح');
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

  Future<void> _printStudentsPDF() async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      // Get students to print
      final studentsToPrint = controller.filteredStudents;

      if (studentsToPrint.isEmpty) {
        showErrorSnackbar('لا يوجد طلاب للطباعة');
        return;
      }

      // Create PDF pages (split if too many students)
      const studentsPerPage = 20;
      final pageCount = (studentsToPrint.length / studentsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * studentsPerPage;
        final endIndex = (startIndex + studentsPerPage > studentsToPrint.length)
            ? studentsToPrint.length
            : startIndex + studentsPerPage;
        final pageStudents = studentsToPrint.sublist(startIndex, endIndex);

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
                      'قائمة الطلاب',
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
                      2: const pw.FlexColumnWidth(1.5), // Nickname
                      3: const pw.FlexColumnWidth(1), // Gender
                      4: const pw.FlexColumnWidth(2.5), // Lectures
                      5: const pw.FlexColumnWidth(2), // Username
                      6: const pw.FlexColumnWidth(1.5), // DOB
                      7: const pw.FlexColumnWidth(2), // Birthplace
                      8: const pw.FlexColumnWidth(1.5), // Nationality
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
                          _buildPdfHeaderCell('الكنية', arabicFontBold),
                          _buildPdfHeaderCell('الجنس', arabicFontBold),
                          _buildPdfHeaderCell('الحلقات', arabicFontBold),
                          _buildPdfHeaderCell('اسم المستخدم', arabicFontBold),
                          _buildPdfHeaderCell('تاريخ الميلاد', arabicFontBold),
                          _buildPdfHeaderCell('مكان الميلاد', arabicFontBold),
                          _buildPdfHeaderCell('الجنسية', arabicFontBold),
                        ],
                      ),

                      // Data rows
                      ...pageStudents.asMap().entries.map((entry) {
                        final index = startIndex + entry.key + 1;
                        final student = entry.value;
                        return pw.TableRow(
                          children: [
                            _buildPdfCell(index.toString(), arabicFont),
                            _buildPdfCell(
                              '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.personalInfo.lastNameAr ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.personalInfo.sex ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.lectures
                                  .map((l) => l.lectureNameAr)
                                  .join(', '),
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.accountInfo.username ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.personalInfo.dateOfBirth ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.personalInfo.placeOfBirth ?? '',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              student.personalInfo.nationality ?? '',
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
                        'إجمالي الطلاب: ${studentsToPrint.length}',
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
        name: 'قائمة_الطلاب.pdf',
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
class _StudentDataSource extends DataGridSource {
  final List<Student> students;
  final StudentManagementController controller;
  final Function(Student) onViewDetails;
  final bool isReadOnly;

  _StudentDataSource({
    required this.students,
    required this.controller,
    required this.onViewDetails,
    this.isReadOnly = false,
  }) {
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void _buildDataGridRows() {
    dataGridRows = students.map<DataGridRow>((student) {
      final cells = <DataGridCell>[];

      // Only add selection checkbox if not in read-only mode
      if (!isReadOnly) {
        cells.add(
            DataGridCell<Student>(columnName: 'selection', value: student));
      }

      // Action button
      cells.addAll([
        DataGridCell<Student>(columnName: 'action', value: student),

        // Name
        DataGridCell<String>(
          columnName: 'name',
          value:
              '${student.personalInfo.firstNameAr ?? ''} ${student.personalInfo.lastNameAr ?? ''}',
        ),

        // Nickname (Last name)
        DataGridCell<String>(
          columnName: 'nickname',
          value: student.personalInfo.lastNameAr ?? '',
        ),

        // Gender
        DataGridCell<String>(
          columnName: 'gender',
          value: student.personalInfo.sex ?? '',
        ),

        // Lectures
        DataGridCell<String>(
          columnName: 'lectures',
          value: student.lectures.map((l) => l.lectureNameAr).join(', '),
        ),

        // Username
        DataGridCell<String>(
          columnName: 'username',
          value: student.accountInfo.username ?? '',
        ),

        // Date of birth
        DataGridCell<String>(
          columnName: 'dob',
          value: student.personalInfo.dateOfBirth ?? '',
        ),

        // Place of birth
        DataGridCell<String>(
          columnName: 'birthplace',
          value: student.personalInfo.placeOfBirth ?? '',
        ),

        // Nationality
        DataGridCell<String>(
          columnName: 'nationality',
          value: student.personalInfo.nationality ?? '',
        ),

        // ID Type
        DataGridCell<String>(
          columnName: 'id_type',
          value: '', // Placeholder as field might not exist yet
        ),
      ]);

      return DataGridRow(cells: cells);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final student = row.getCells()[0].value as Student;
    final isSelected = controller.isStudentSelected(student);

    return DataGridRowAdapter(
      color: isSelected ? Colors.teal.shade50 : null,
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'selection') {
          // Only show checkbox if not in read-only mode
          if (!isReadOnly) {
            return Center(
              child: Obx(() => Checkbox(
                    value: controller.isStudentSelected(student),
                    onChanged: (value) {
                      controller.toggleStudentSelection(student);
                    },
                  )),
            );
          } else {
            return const SizedBox.shrink();
          }
        }

        if (cell.columnName == 'action') {
          return Center(
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
              tooltip: 'عرض التفاصيل',
              onPressed: () => onViewDetails(student),
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
