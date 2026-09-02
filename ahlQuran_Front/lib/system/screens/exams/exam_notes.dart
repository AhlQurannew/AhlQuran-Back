import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/appreciation.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/base_layout.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/exams/exam_notes.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_grid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_show.dart';

class ExamNotes extends StatelessWidget {
  const ExamNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: BaseLayout(
            title: "Exam Notes Management",
            child: ManagementScreen<Appreciation>(
                deleteEndpoint: (appreciation) =>
                    ApiEndpoints.getAppreciationById(
                        appreciation.appreciationId),
                dataSourceEndpoint: ApiEndpoints.getAppreciations,
                managementType: ManagementTypes.examNotes,
                dialog: AppreciationDialog(),
                rowBuilder: (exam) => [
                      DataGridCell<String>(
                          columnName: 'id',
                          value: exam.appreciationId.toString()),
                      DataGridCell<int>(
                          columnName: 'min_point', value: exam.pointMin),
                      DataGridCell<int>(
                          columnName: 'max_point', value: exam.pointMax),
                      DataGridCell<String>(
                          columnName: 'note', value: exam.note),
                      DataGridCell<String>(columnName: 'button', value: null),
                    ],
                columnsNames: [
                  GridColumn(
                      columnName: 'id',
                      label: ManagementGrid.buildHeader('ID')),
                  GridColumn(
                      columnName: 'max_point',
                      label: ManagementGrid.buildHeader('Max Point')),
                  GridColumn(
                      columnName: 'min_point',
                      label: ManagementGrid.buildHeader('Min Point')),
                  GridColumn(
                      columnName: 'note',
                      label: ManagementGrid.buildHeader('Note')),
                  GridColumn(
                    columnName: 'button',
                    label: ManagementGrid.buildHeader('Action'),
                    allowSorting: false,
                    allowFiltering: false,
                  ),
                ])));
  }
}
