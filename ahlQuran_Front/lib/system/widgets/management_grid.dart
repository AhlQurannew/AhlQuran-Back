import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import '../new_models/grid/generic_data_grid.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ManagementGrid<T extends Model> extends StatelessWidget {
  final List<T> data;
  final List<DataGridCell> Function(T obj) rowBuilder;
  final List<GridColumn> columnsNames;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function() onRefresh;
  final void Function(T?)? getObj;

  const ManagementGrid({
    super.key,
    required this.data,
    required this.onDelete,
    required this.onRefresh,
    this.getObj,
    required this.rowBuilder,
    required this.columnsNames,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<T>(
      data: data,
      // selectionMode: SelectionMode.singleDeselect,
      getObj: (row) {
        if (getObj != null) {
          getObj!(row);
        }
      },
      onDelete: onDelete,
      onRefresh: onRefresh,
      screenTitle: 'Students List',
      detailsTitle: 'Student Details',
      showCheckBoxColumn: true,
      idExtractor: (row) => int.parse(row.getCells()[0].value),
      rowBuilder: (student) => DataGridRow(cells: rowBuilder(student)),
      columns: columnsNames,
    );
  }

  static Widget buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(title, overflow: TextOverflow.ellipsis),
    );
  }
}
