import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/base_layout.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/exams/exam_types.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_grid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_show.dart';

class ExamTypes extends StatelessWidget {
  const ExamTypes({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: BaseLayout(
            title: "Exam types Management",
            child: ManagementScreen<Exam>(
              dataSourceEndpoint: ApiEndpoints.getExams,
              deleteEndpoint: (exam) => ApiEndpoints.getExamById(exam.examId),
              managementType: ManagementTypes.students,
              dialog: ExamTypesDialog(),
              rowBuilder: (exam) => [
                DataGridCell<String>(
                    columnName: 'id', value: exam.examId.toString()),
                DataGridCell<String>(
                    columnName: 'exam_name', value: exam.examNameAr),
                DataGridCell<int>(
                    columnName: 'max_point', value: exam.examMaxPoint),
                DataGridCell<int>(
                    columnName: 'min_point', value: exam.examSucessMinPoint),
                DataGridCell<String>(columnName: 'type', value: exam.examType),
                DataGridCell<int>(
                    columnName: 'exam_memo_point', value: exam.examMemoPoint),
                DataGridCell<int>(
                    columnName: 'exam_tjwid_app_point',
                    value: exam.examTjwidAppPoint),
                DataGridCell<int>(
                    columnName: 'exam_tjwid_tho_point',
                    value: exam.examTjwidThoPoint),
                DataGridCell<int>(
                    columnName: 'exam_performance_point',
                    value: exam.examPerformancePoint),
                DataGridCell<String>(columnName: 'button', value: null),
              ],
              columnsNames: [
                GridColumn(
                    columnName: 'id', label: ManagementGrid.buildHeader('ID')),
                GridColumn(
                    columnName: 'exam_name',
                    label: ManagementGrid.buildHeader('Exam Name')),
                GridColumn(
                    columnName: 'max_point',
                    label: ManagementGrid.buildHeader('Max Point')),
                GridColumn(
                    columnName: 'min_point',
                    label: ManagementGrid.buildHeader('Min Point')),
                GridColumn(
                    columnName: 'type',
                    label: ManagementGrid.buildHeader('Type')),
                GridColumn(
                    columnName: 'exam_memo_point',
                    label: ManagementGrid.buildHeader('Memorization Point')),
                GridColumn(
                    columnName: 'exam_tjwid_app_point',
                    label:
                        ManagementGrid.buildHeader('Tjwid Applicative Point')),
                GridColumn(
                    columnName: 'exam_tjwid_tho_point',
                    label: ManagementGrid.buildHeader('Tjwid Theoric Point')),
                GridColumn(
                    columnName: 'exam_performance_point',
                    label: ManagementGrid.buildHeader('Performance Point')),
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
