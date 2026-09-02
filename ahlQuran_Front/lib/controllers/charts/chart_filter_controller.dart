import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/date_picker.dart';
import '../../system/utils/snackbar_helper.dart';

/// Controller for managing filters in chart/report view
class ChartFilterController extends GetxController {
  final String tag;

  /// Input controllers
  final lectureNameController = TextEditingController();
  final studentNameController = TextEditingController();

  /// Filter state
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final isFilterApplied = false.obs;
  final isLoading = false.obs;

  ChartFilterController({required this.tag});

  @override
  void onInit() {
    super.onInit();
    _setDefaultDates(); // Initialize with previous month's range
  }

  /// Set default date range to previous month
  void _setDefaultDates() {
    final now = DateTime.now();
    final previousMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;

    fromDate.value = DateTime(year, previousMonth, 1);
    toDate.value = DateTime(year, previousMonth + 1, 0); // Last day of month
  }

  /// Validate that both dates are selected and correct
  bool canApply() {
    if (fromDate.value == null || toDate.value == null) {
      showErrorSnackbar('يرجى تحديد تاريخ البداية والنهاية');
      return false;
    }

    if (fromDate.value!.isAfter(toDate.value!)) {
      showErrorSnackbar('تاريخ البداية يجب أن يكون قبل النهاية');
      return false;
    }

    return true;
  }

  /// Show date picker for from/to dates
  Future<void> pickDate(
    BuildContext context, {
    required bool isFrom,
  }) async {
    final initialDate =
        (isFrom ? fromDate.value : toDate.value) ?? DateTime.now();

    final selectedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isFrom ? DateTime(2000) : (fromDate.value ?? DateTime(2000)),
      lastDate: isFrom ? (toDate.value ?? DateTime(2030)) : DateTime(2030),
    );

    dev.log("Selected date: $selectedDate");

    if (selectedDate != null) {
      if (isFrom) {
        fromDate.value = selectedDate;
      } else {
        toDate.value = selectedDate;
      }
    }
  }

  /// Apply current filters if valid
  void applyFilters() {
    if (canApply()) {
      isFilterApplied.value = true;
    }
  }

  /// Reset all filters and inputs to default
  void resetFilters() {
    lectureNameController.clear();
    studentNameController.clear();
    _setDefaultDates();
    isFilterApplied.value = false;
  }

  /// Format fromDate for display
  String get formattedFromDate => fromDate.value != null
      ? DateFormat('yyyy-MM-dd').format(fromDate.value!)
      : '';

  /// Format toDate for display
  String get formattedToDate => toDate.value != null
      ? DateFormat('yyyy-MM-dd').format(toDate.value!)
      : '';

  @override
  void onClose() {
    lectureNameController.dispose();
    studentNameController.dispose();
    super.onClose();
  }
}
