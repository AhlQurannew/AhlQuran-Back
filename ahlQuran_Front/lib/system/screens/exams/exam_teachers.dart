import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/exam_teachers_from.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/base_layout.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/exams/exam_teachers.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_grid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_show.dart';

class ExamTeachers extends StatelessWidget {
  const ExamTeachers({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: BaseLayout(
            title: "Exam Teachers Management",
            child: ManagementScreen<ExamTeacherInfoDialog>(
              dataSourceEndpoint: ApiEndpoints.getSpecialExamsTeachers,
              deleteEndpoint: (examTeacher) =>
                  ApiEndpoints.deleteExamTeacherByTeacherId(
                      examTeacher.techer.teacherId),
              managementType: ManagementTypes.examTeacher,
              dialog: ExamTeachersDialog(),
              rowBuilder: (exam) => [
                DataGridCell<String>(
                    columnName: 'id',
                    value: exam.techer.teacherAccountId.toString()),
                DataGridCell<String>(
                    columnName: 'exam_name',
                    value: exam.exam.isNotEmpty
                        ? exam.exam.map((e) => e.examNameAr).join(', ')
                        : "غير مسؤول عن اي اختبار"),
                DataGridCell<String>(
                    columnName: 'teacher_name',
                    value: '${exam.techer.firstName} ${exam.techer.lastName}'),
                DataGridCell<String>(columnName: 'button', value: null),
              ],
              columnsNames: [
                GridColumn(
                    columnName: 'id', label: ManagementGrid.buildHeader('ID')),
                GridColumn(
                    columnName: 'exam_name',
                    label: ManagementGrid.buildHeader('Exam Name')),
                GridColumn(
                    columnName: 'teacher_name',
                    label: ManagementGrid.buildHeader('Teacher Name')),
                GridColumn(
                  columnName: 'button',
                  label: ManagementGrid.buildHeader('Action'),
                  allowSorting: false,
                  allowFiltering: false,
                ),
              ],
            )));
  }
}
