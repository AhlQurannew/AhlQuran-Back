import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_buttons_menu.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_grid.dart';
import 'error_illustration.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';

enum ManagementTypes {
  students(value: "students"),
  guardians(value: "guardians"),
  examTeacher(value: "exam teachers"),
  examTypes(value: "exam types"),
  examRecords(value: "exam records"),
  examNotes(value: "exam notes"),
  lectures(value: "lectures");

  final String value;
  const ManagementTypes({required this.value});
}

class ManagementScreen<T extends Model> extends StatefulWidget {
  final String Function(T selectedModel) deleteEndpoint;
  final String dataSourceEndpoint;
  final List<DataGridCell> Function(T obj) rowBuilder;
  final List<GridColumn> columnsNames;
  final GlobalDialog dialog;
  final ManagementTypes managementType;

  const ManagementScreen({
    super.key,
    required this.deleteEndpoint,
    required this.rowBuilder,
    required this.columnsNames,
    required this.managementType,
    required this.dialog,
    required this.dataSourceEndpoint,
  });

  @override
  State<ManagementScreen<T>> createState() => _ManagementScreenState<T>();
}

class _ManagementScreenState<T extends Model>
    extends State<ManagementScreen<T>> {
  late GenericController<T> controller;
  late GenericEditController<T> editController;
  final Rxn<T> selectedItem = Rxn<T>();
  final RxBool hasSelection = false.obs;

  final Duration delay = const Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    controller = Get.find<GenericController<T>>();

    editController = Get.isRegistered<GenericEditController<T>>()
        ? Get.find<GenericEditController<T>>()
        : Get.put(GenericEditController<T>(initialmodel: null, isEdit: false));

    _loadData();
  }

  Future<void> _loadData() async {
    controller.isLoading.value = true;

    try {
      await Future.wait([
        Future.delayed(delay),
        controller.fetchlistOfModels(
            widget.dataSourceEndpoint), // Consider making this dynamic
      ]);
    } catch (e) {
      controller.errorMessage.value = e.toString();
    } finally {
      if (mounted) controller.isLoading.value = false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (Get.isRegistered<GenericEditController<T>>()) {
      Get.delete<GenericEditController<T>>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Obx(() => TopButtons(
                onAdd: () {
                  if (Get.isRegistered<GenericEditController<T>>()) {
                    Get.delete<GenericEditController<T>>();
                  }
                  Get.put(GenericEditController<T>(
                    initialmodel: null,
                    isEdit: false,
                  ));
                  Get.dialog(widget.dialog);
                },
                onEdit: () {
                  if (selectedItem.value != null) {
                    if (Get.isRegistered<GenericEditController<T>>()) {
                      Get.delete<GenericEditController<T>>();
                    }
                    Get.put(GenericEditController<T>(
                      initialmodel: selectedItem.value,
                      isEdit: true,
                    ));
                    Get.dialog(widget.dialog);
                  }
                },
                onDelete: () async {
                  if (selectedItem.value == null) {
                    dev.log('Error :: No item selected for deletion');
                    return;
                  }

                  await ApiService.delete(
                      widget.deleteEndpoint(selectedItem.value!));

                  selectedItem.value = null;
                  hasSelection.value = false;
                  _loadData();
                },
                hasSelection: hasSelection.value,
              )),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: ThreeBounce());
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return ErrorIllustration(
                illustrationPath: 'assets/illustration/bad-connection.svg',
                title: 'Connection Error',
                message: controller.errorMessage.value,
                onRetry: _loadData,
              );
            }

            if (controller.listOfModels.isEmpty) {
              return ErrorIllustration(
                illustrationPath: 'assets/illustration/empty-box.svg',
                title: 'No ${widget.managementType.value} Found',
                message:
                    'There are no ${widget.managementType.value} registered yet. Click the add button to create one.',
              );
            }

            return ManagementGrid<T>(
              rowBuilder: widget.rowBuilder,
              columnsNames: widget.columnsNames,
              data: controller.listOfModels,
              onRefresh: _loadData,
              onDelete: (id) => controller.postDelete(
                ApiEndpoints.getStudents, // consider making dynamic
                id,
              ),
              getObj: (obj) {
                selectedItem.value = obj;
                hasSelection.value = obj != null;
              },
            );
          }),
        ),
      ],
    );
  }
}
