import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'generic_data_source.dart';
import 'data_exporter.dart';
import 'dart:developer' as dev;

class GenericDataGrid<T> extends StatefulWidget {
  final List<T> data;
  final Future<void> Function(int id)? onDelete;
  final DataGridRow Function(T model) rowBuilder;
  final Widget? Function(DataGridCell cell)? cellBuilder;
  final List<GridColumn> columns;
  final dynamic Function(DataGridRow row) idExtractor;
  final String screenTitle;
  final String detailsTitle;
  final int initialRowsPerPage;
  final List<int> availableRowsPerPage;
  final SelectionMode selectionMode;
  final bool showCheckBoxColumn;
  final IconData infoIcon;
  final IconData deleteIcon;
  final Color? selectionColor;
  final Future<void> Function() onRefresh;
  final void Function(DataGridRow? selectedRow)? getDataGridRow;
  final void Function(T? obj)? getObj;
  final bool enablePagination;
  final ValueChanged<int?>? onRowsPerPageChanged;
  final Color? paginationBackgroundColor;
  final Color? paginationTextColor;

  const GenericDataGrid({
    super.key,
    required this.data,
    required this.onDelete,
    required this.rowBuilder,
    required this.columns,
    required this.idExtractor,
    required this.onRefresh,
    this.cellBuilder,
    this.screenTitle = 'Data Grid',
    this.detailsTitle = 'Item Details',
    this.initialRowsPerPage = 10,
    this.availableRowsPerPage = const [5, 10, 20, 50],
    this.selectionMode = SelectionMode.singleDeselect,
    this.showCheckBoxColumn = false,
    this.infoIcon = Icons.info_outline,
    this.deleteIcon = Icons.delete,
    this.selectionColor,
    this.getDataGridRow,
    this.getObj,
    this.enablePagination = true,
    this.onRowsPerPageChanged,
    this.paginationBackgroundColor,
    this.paginationTextColor,
  });

  @override
  State<GenericDataGrid<T>> createState() => _GenericDataGridState<T>();
}

class _GenericDataGridState<T> extends State<GenericDataGrid<T>> {
  late DataGridController _controller;
  late GenericDataSource<T> _dataSource;
  late int _rowsPerPage;

  @override
  void initState() {
    super.initState();
    _controller = DataGridController();
    _rowsPerPage = widget.initialRowsPerPage;
    _initializeDataSource();
  }

  @override
  void didUpdateWidget(GenericDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.initialRowsPerPage != widget.initialRowsPerPage) {
      _rowsPerPage = widget.initialRowsPerPage;
      _initializeDataSource();
    }
  }

  void _initializeDataSource() {
    _dataSource = GenericDataSource<T>(
      data: widget.data,
      gridController: _controller,
      onDelete: widget.onDelete,
      onRefresh: widget.onRefresh,
      rowBuilder: widget.rowBuilder,
      idExtractor: widget.idExtractor,
      detailsTitle: widget.detailsTitle,
      cellBuilder: widget.cellBuilder,
      infoIcon: widget.infoIcon,
      deleteIcon: widget.deleteIcon,
      selectionColor: widget.selectionColor,
      rowsPerPage: _rowsPerPage,
      onRowsPerPageChanged: widget.onRowsPerPageChanged,
      columns: widget.columns,
    );
  }

  void _exportToExcel() {
    DataExporter.exportToExcel<T>(
      data: widget.data,
      columns: widget.columns,
      rowBuilder: widget.rowBuilder,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              selectionColor: widget.selectionColor ??
                  Color(0xFFC78D20).withValues(alpha: 0.1),
            ),
            child: SfDataGrid(
              controller: _controller,
              source: _dataSource,
              columns: widget.columns,
              columnWidthMode: ColumnWidthMode.fill,
              selectionMode: widget.selectionMode,
              showCheckboxColumn: widget.showCheckBoxColumn,
              allowSorting: true,
              allowFiltering: true,
              gridLinesVisibility: GridLinesVisibility.both,
              headerGridLinesVisibility: GridLinesVisibility.both,
              onCheckboxValueChanged: (details) {
                if (details.value == true) {
                  final selectedRow = details.row;
                  if (selectedRow != null) {
                    final rowId = widget.idExtractor(selectedRow);
                    final obj = _dataSource.getModelFromRow(selectedRow);
                    widget.getObj?.call(obj);
                    widget.getDataGridRow?.call(selectedRow);
                    dev.log('Checkbox changed for row ID: $rowId');
                    dev.log('Original model: $obj');
                  }
                } else {
                  widget.getObj?.call(null);
                  widget.getDataGridRow?.call(null);
                }
              },
            ),
          ),
        ),
        if (widget.enablePagination)
          SfDataPager(
            delegate: _dataSource,
            pageCount: (widget.data.length / _rowsPerPage).ceilToDouble(),
            visibleItemsCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 5),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: widget.onRefresh,
                child: const Icon(Icons.refresh),
              ),
              FloatingActionButton(
                mini: true,
                onPressed: _exportToExcel,
                child: const Icon(Icons.file_download),
              ),
              if (widget.onDelete != null &&
                  _controller.selectedRows.isNotEmpty)
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    final selectedRow = _controller.selectedRows.first;
                    final id = widget.idExtractor(selectedRow);
                    widget.onDelete?.call(id as int);
                  },
                  child: Icon(widget.deleteIcon),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
