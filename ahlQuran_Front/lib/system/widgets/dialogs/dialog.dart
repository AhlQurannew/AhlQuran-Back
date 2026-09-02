import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/form_controller.dart'
    as form;
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';
import 'common/dialog_header.dart';
import 'common/dialog_submit_button.dart';

/// Abstract dialog that provides a template for forms with optional edit support.
abstract class GlobalDialog extends StatefulWidget {
  final String dialogHeader;
  final int numberInputs;

  const GlobalDialog({
    super.key,
    this.dialogHeader = "add data",
    this.numberInputs = 10,
  });

  @override
  State<GlobalDialog> createState();
}

/// Base state class for form dialogs.
/// Subclasses should define formChild, loadData, submit, setDefaultFieldsValue.
abstract class DialogState<GEC extends GenericEditController>
    extends State<GlobalDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late ScrollController scrollController;
  late form.FormController formController;
  GEC? editController;
  RxBool isComplete = true.obs;

  /// Returns form fields as a Column.
  List<Widget> formChild();

  /// Load any necessary data (e.g. dropdowns, lists).
  Future<void> loadData();

  /// Submit the form data.
  Future<bool> submit();

  /// Pre-fill form when editing.
  void setDefaultFieldsValue();

  @override
  void initState() {
    super.initState();
    debugPrint('=== DIALOG initState CALLED ===');
    debugPrint('Dialog instance hashCode: ${hashCode}');
    debugPrint('Widget type: ${widget.runtimeType}');

    loadData();

    // Check for tagged FormController first (for nested dialogs like guardian in student)
    if (Get.isRegistered<form.FormController>(tag: 'guardian')) {
      formController = Get.find<form.FormController>(tag: 'guardian');
    } else if (!Get.isRegistered<form.FormController>()) {
      Get.put(form.FormController(widget.numberInputs));
      formController = Get.find<form.FormController>();
    } else {
      formController = Get.find<form.FormController>();
    }

    if (Get.isRegistered<GEC>()) {
      editController = Get.find<GEC>();
    }

    scrollController = ScrollController();

    if (editController?.model.value != null) {
      setDefaultFieldsValue();
    }
  }

  @override
  void dispose() {
    debugPrint('=== DIALOG dispose CALLED ===');
    debugPrint('Dialog instance hashCode: ${hashCode}');

    scrollController.dispose();
    // Don't dispose formController if it's tagged (managed externally)
    if (!Get.isRegistered<form.FormController>(tag: 'guardian')) {
      formController.dispose();
    }
    if (Get.isRegistered<ScrollController>()) {
      Get.delete<ScrollController>();
    }
    // Don't delete tagged FormController (managed by parent dialog)
    if (Get.isRegistered<form.FormController>() &&
        !Get.isRegistered<form.FormController>(tag: 'guardian')) {
      Get.delete<form.FormController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sections = formChild();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        debugPrint(
            'PopScope onPopInvokedWithResult: didPop=$didPop, result=$result');
        if (!didPop) {
          debugPrint('PopScope calling _handleExit...');
          _handleExit();
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 300,
          maxWidth: Get.width * 0.45,
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Header section (title + close button)
              DialogHeader(
                title: widget.dialogHeader,
                onClose: _handleExit,
              ),

              /// Form content with scroll
              LayoutBuilder(
                builder: (context, constraints) {
                  // Estimate the height of each section (adjust as needed)
                  const double itemHeight = 90.0; // or measure dynamically
                  const double separatorHeight = 10.0;
                  final totalHeight = sections.length * itemHeight +
                      (sections.length - 1) * separatorHeight +
                      40; // padding

                  // Set a max height (e.g., 400 or 60% of screen height if unbounded)
                  final maxHeight = constraints.hasBoundedHeight &&
                          constraints.maxHeight < double.infinity
                      ? constraints.maxHeight * 0.8
                      : Get.height * 0.8;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          totalHeight < maxHeight ? totalHeight : maxHeight,
                    ),
                    child: Form(
                      key: formKey,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          scrollbarTheme: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(
                                const Color(0xFF4DB6AC)),
                            trackColor: WidgetStateProperty.all(
                                const Color(0xFF4DB6AC).withOpacity(0.2)),
                            trackBorderColor:
                                WidgetStateProperty.all(Colors.transparent),
                            thickness: WidgetStateProperty.all(8.0),
                            radius: const Radius.circular(4),
                            thumbVisibility: WidgetStateProperty.all(true),
                            trackVisibility: WidgetStateProperty.all(true),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            thickness: 8.0,
                            radius: const Radius.circular(4),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  children: [
                                    for (int i = 0;
                                        i < sections.length;
                                        i++) ...[
                                      RepaintBoundary(
                                        child: sections[i],
                                      ),
                                      if (i < sections.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              /// Submit button at bottom
              DialogSubmitButton(
                isComplete: isComplete,
                onSubmit: _handleSubmit,
                onCancel: _handleExit,
                isEditMode: editController?.model.value != null,
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Handles exit without saving
  void _handleExit() {
    try {
      debugPrint('Attempting to close dialog...');
      // Use Navigator.pop directly since PopScope blocks Get.back()
      Navigator.of(context, rootNavigator: false).pop(false);
      debugPrint('Dialog closed successfully');
    } catch (e) {
      debugPrint('Error in _handleExit: $e');
      // Try with root navigator as fallback
      try {
        Navigator.of(context, rootNavigator: true).pop(false);
      } catch (e2) {
        debugPrint('Error in fallback Navigator.pop: $e2');
      }
    }
  }

  /// Handles form validation and submission.
  Future<void> _handleSubmit() async {
    debugPrint('=== DIALOG _handleSubmit CALLED ===');
    debugPrint('Dialog instance hashCode: ${hashCode}');
    debugPrint('isComplete.value BEFORE: ${isComplete.value}');
    debugPrint('editController?.model.value: ${editController?.model.value}');
    debugPrint('Form valid: ${formKey.currentState?.validate()}');
    debugPrint(
        'Fields: ${formController.controllers.map((c) => c.text).toList()}');

    isComplete.value = false;
    debugPrint('isComplete.value set to: ${isComplete.value}');

    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      debugPrint('Form saved, calling submit()...');

      try {
        final success = await submit();
        debugPrint('Submit returned: $success');
        debugPrint('isComplete.value AFTER submit: ${isComplete.value}');
        if (success) {
          debugPrint('Success! Closing dialog with result=true');
          debugPrint('Using Navigator.pop() instead of Get.back()...');
          // Use Navigator.pop directly to bypass PopScope canPop: false
          Navigator.of(context, rootNavigator: false).pop(true);
          debugPrint('Navigator.pop() completed');
        } else {
          debugPrint('Submit failed, keeping dialog open');
        }
      } catch (e, stackTrace) {
        debugPrint('Error submitting form: $e');
        debugPrint('Stack trace: $stackTrace');
        showErrorSnackbar('حدث خطأ أثناء الحفظ');
      } finally {
        debugPrint('Finally block: setting isComplete.value to true');
        isComplete.value = true;
        debugPrint('isComplete.value FINAL: ${isComplete.value}');
      }
    } else {
      debugPrint('Form validation failed');
      showErrorSnackbar('الرجاء ملء جميع الحقول المطلوبة');
      isComplete.value = true;
    }
  }
}
