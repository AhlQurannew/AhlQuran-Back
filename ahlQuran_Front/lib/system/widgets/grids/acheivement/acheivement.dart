import 'package:flutter/material.dart';
import '../../../new_models/grid/generic_data_grid.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../new_models/acheivement_class.dart';
import 'package:get/get.dart';
import '/system/widgets/dialogs/acheivement.dart';
import '/controllers/latest_acheivement.dart';

class AcheivementGrid extends StatelessWidget {
  final List<Acheivement> data;
  final Future<void> Function() onRefresh;
  final String date;
  final int sessionId;

  const AcheivementGrid({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.date,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GenericDataGrid<Acheivement>(
      data: data,
      onRefresh: onRefresh,
      onDelete: null,
      selectionMode: SelectionMode.none,
      screenTitle: 'Students List',
      detailsTitle: 'Student Achievement Details',
      showCheckBoxColumn: false,
      idExtractor: (row) => int.parse(row.getCells()[0].value),
      rowBuilder: (achievement) => DataGridRow(cells: [
        DataGridCell<String>(
          columnName: 'student_id',
          value: achievement.studentID.toString(),
        ),
        DataGridCell<String>(
          columnName: 'full_name',
          value: achievement.studentName,
        ),
        DataGridCell<Widget>(
          columnName: 'achievement',
          value: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final studentId = achievement.studentID;
                Get.put(LatestAcheivement());
                Get.dialog(
                  AcheivemtDialog(
                    sessionId: sessionId,
                    studentId: studentId,
                    date: date,
                  ),
                ).then((_) => onRefresh());
              },
              child: Icon(
                Icons.emoji_events,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ),
        DataGridCell<Widget>(
          columnName: 'attendance',
          value: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Get.dialog(
                  AttendanceDialog(data: data),
                ).then((_) => onRefresh());
              },
              child: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ),
      ]),
      cellBuilder: (cell) {
        if (cell.columnName == 'achievement' ||
            cell.columnName == 'attendance') {
          return Container(
            alignment: Alignment.center,
            child: cell.value as Widget,
          );
        }
        return null;
      },
      columns: [
        GridColumn(
          columnName: 'student_id',
          label: _buildHeader('Student ID'),
          allowSorting: true,
          allowFiltering: true,
        ),
        GridColumn(
          columnName: 'full_name',
          label: _buildHeader('Student Name'),
          allowSorting: true,
          allowFiltering: true,
        ),
        GridColumn(
          columnName: 'achievement',
          label: _buildHeader('Achievement'),
          allowSorting: false,
          allowFiltering: false,
          width: 100,
        ),
        GridColumn(
          columnName: 'attendance',
          label: _buildHeader('Attendance'),
          allowSorting: false,
          allowFiltering: false,
          width: 100,
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AttendanceController extends GetxController {
  final RxMap<String, String?> studentAttendance = <String, String?>{}.obs;

  void selectAttendance(String studentID, String type) {
    if (studentAttendance[studentID] == type) {
      studentAttendance[studentID] = null;
    } else {
      studentAttendance[studentID] = type;
    }
  }

  void toggleAllForType(String type, bool shouldSelect) {
    if (shouldSelect) {
      studentAttendance.updateAll((key, value) => type);
    } else {
      studentAttendance.updateAll((key, value) => value == type ? null : value);
    }
  }

  bool isAllSelectedForType(String type) {
    if (studentAttendance.isEmpty) return false;
    return studentAttendance.values.every((value) => value == type);
  }

  bool isAnySelectedForType(String type) {
    return studentAttendance.values.any((value) => value == type);
  }

  @override
  void onClose() {
    studentAttendance.clear();
    super.onClose();
  }
}

class AttendanceDialog extends StatelessWidget {
  final List<Acheivement> data;
  final AttendanceController controller = Get.put(AttendanceController());
  final ScrollController scrollController = ScrollController();

  AttendanceDialog({super.key, required this.data}) {
    for (var student in data) {
      controller.studentAttendance[student.studentID.toString()] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: Get.width * 0.7,
        maxHeight: Get.height * 0.8,
        minHeight: 400,
        minWidth: 300,
      ),
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                      ),
                      Text(
                        "Attendance",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Student',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _buildTableHeader('Present'),
                        _buildTableHeader('Absent'),
                        _buildTableHeader('Late'),
                        _buildTableHeader('Excuse'),
                      ],
                    ),
                    ...data.map((student) => _buildStudentRow(student)),
                  ],
                ),
                SizedBox(height: 10),
                TextButton(onPressed: () => Get.back(), child: Text("close"))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String label) {
    final type = label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [Text(label), _buildSelectAllCheckbox(type)],
      ),
    );
  }

  TableRow _buildStudentRow(Acheivement student) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(student.studentName),
        ),
        _buildAttendanceCell(student.studentID.toString(), 'present'),
        _buildAttendanceCell(student.studentID.toString(), 'absent'),
        _buildAttendanceCell(student.studentID.toString(), 'late'),
        _buildAttendanceCell(student.studentID.toString(), 'excuse'),
      ],
    );
  }

  Widget _buildAttendanceCell(
    String studentID,
    String type,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () => controller.selectAttendance(studentID, type),
        child: Obx(() {
          final isSelected = controller.studentAttendance[studentID] == type;
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(),
              color: isSelected ? Colors.black : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(String type) {
    return Obx(() {
      final allSelected = controller.isAllSelectedForType(type);
      final anySelected = controller.isAnySelectedForType(type);

      return Checkbox(
        value: allSelected ? true : (anySelected ? null : false),
        tristate: true,
        onChanged: (value) {
          controller.toggleAllForType(type, value ?? false);
        },
      );
    });
  }
}
