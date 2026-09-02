import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'dart:developer' as dev;

/// A generic data source for Syncfusion DataGrid to manage data rows and actions.
class GenericDataSource<T> extends DataGridSource {
  final List<T> data;
  final Map<DataGridRow, T> _rowToModelMap = {};
  final DataGridController gridController;
  final Future<void> Function(int id)? onDelete;
  final Future<void> Function() onRefresh;
  final DataGridRow Function(T model) rowBuilder;
  final dynamic Function(DataGridRow row) idExtractor;
  final String detailsTitle;
  final Widget? Function(DataGridCell cell)? cellBuilder;
  final IconData infoIcon;
  final IconData deleteIcon;
  final IconData exportIcon;
  final Color? selectionColor;
  final int rowsPerPage;
  final ValueChanged<int?>? onRowsPerPageChanged;
  final List<GridColumn> columns;

  GenericDataSource({
    required this.data,
    required this.gridController,
    required this.onDelete,
    required this.onRefresh,
    required this.rowBuilder,
    required this.idExtractor,
    this.detailsTitle = 'Item Details',
    this.cellBuilder,
    this.infoIcon = Icons.info_outline,
    this.deleteIcon = Icons.delete,
    this.exportIcon = Icons.download,
    this.selectionColor,
    required this.rowsPerPage,
    this.onRowsPerPageChanged,
    required this.columns,
  }) {
    _data = data;
    _buildDataGridRows();
  }

  List<T> _data = [];
  late List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  /// Refreshes the data source with new data.
  void updateDataSource(List<T> newData) {
    _data = newData;
    _buildDataGridRows();
    notifyListeners();
  }

  /// Builds data grid rows from the model list.
  void _buildDataGridRows() {
    _rowToModelMap.clear();
    _rows = _data.map<DataGridRow>((e) {
      final row = rowBuilder(e);
      _rowToModelMap[row] = e;
      return row;
    }).toList();
  }

  /// Retrieves the model object from a specific row.
  T? getModelFromRow(DataGridRow row) => _rowToModelMap[row];

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final isSelected = gridController.selectedRows.contains(row);
    final cells = row.getCells();

    return DataGridRowAdapter(
      color:
          isSelected ? (selectionColor ?? Colors.white.withOpacity(0.0)) : null,
      cells: cells.map<Widget>((cell) {
        if (cell.columnName == 'button') {
          return _buildActionCell(row);
        }
        return _buildDataCell(cell);
      }).toList(),
    );
  }

  /// Builds the action cell with an info icon.
  Widget _buildActionCell(DataGridRow row) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: GestureDetector(
        child: Icon(infoIcon, color: Theme.of(Get.context!).primaryColor),
        onTap: () => _showRowDetails(row),
      ),
    );
  }

  /// Builds a standard data cell.
  Widget _buildDataCell(DataGridCell cell) {
    return cellBuilder?.call(cell) ??
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell.value?.toString() ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        );
  }

  /// Shows a confirmation dialog for deleting a row item.
  Future<void> _showDeleteDialog(DataGridRow row) async {
    final context = Get.context!;
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        title: Text('Confirm Deletion',
            style: Theme.of(context).textTheme.headlineSmall),
        content: Text('Are you sure you want to delete this item?',
            style: Theme.of(context).textTheme.bodyLarge),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final id = idExtractor(row);
        await onDelete?.call(id);
        await onRefresh();
        showSuccessSnackbar('Item deleted successfully');
      } catch (e) {
        dev.log('Delete error: $e');
        showErrorSnackbar('Failed to delete item');
      }
    }
  }

  /// Shows a dialog with row details.
  void _showRowDetails(DataGridRow row) {
    final context = Get.context!;
    final details =
        row.getCells().where((c) => c.columnName != 'button').map((cell) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                '${cell.columnName}:',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Expanded(
              child: SelectableText(
                cell.value?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }).toList();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        title: Text(detailsTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        content: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: 600, maxHeight: Get.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details),
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton(onPressed: Get.back, child: const Text('Close'))
        ],
      ),
    );
  }
}
