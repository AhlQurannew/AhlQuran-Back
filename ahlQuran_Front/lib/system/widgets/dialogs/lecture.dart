import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/lecture_management_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import '../../utils/const/lecture.dart';
import '../drop_down.dart';
import '../../../controllers/submit_form.dart';
import '../../new_models/forms/lecture_form.dart';
import '../../../controllers/validator.dart';
import '../custom_container.dart';
import '../input_field.dart';
import '../custom_matrix.dart';
import '../multiselect.dart';
import 'dart:developer' as dev;

class LectureDialog extends GlobalDialog {
  const LectureDialog({
    super.key,
    super.dialogHeader = "إضافة حصة", // Add Lecture
    super.numberInputs = 2,
  });

  @override
  State<GlobalDialog> createState() =>
      _LectureDialogState<GenericEditController<LectureForm>>();
}

class _LectureDialogState<GEC extends GenericEditController<LectureForm>>
    extends DialogState<GEC> {
  // Data Loading
  @override
  Future<void> loadData() async {
    try {
      final fetchedTeachernNames =
          await getItems<Teacher>(ApiEndpoints.getTeachers, Teacher.fromJson);

      dev.log('teacherNames: ${fetchedTeachernNames.toString()}');

      setState(() {
        teacherResult = fetchedTeachernNames;
        dev.log('teacherNames: ${teacherResult.toString()}');

        // Set default values after loading teacher list
        if (editController?.model.value != null) {
          setDefaultFieldsValue();
        }
      });
    } catch (e) {
      dev.log("Error loading data: $e");
    }
  }

  // State Variables
  TimeCellController? _timeCellController;
  TimeCellController get timeCellController {
    if (_timeCellController == null) {
      if (!Get.isRegistered<TimeCellController>()) {
        Get.put(TimeCellController());
      }
      _timeCellController = Get.find<TimeCellController>();
    }
    return _timeCellController!;
  }

  final lectureInfo = LectureForm();
  MultiSelectResult<Teacher>? teacherResult;
  String selectedLectureType = type.isNotEmpty ? type[0] : '';
  bool showOnWebsite = true;
  List<MultiSelectItem<Teacher>>? selectedTeachers = [];

  // Lifecycle Methods
  @override
  void initState() {
    super.initState();
    // Initialize the TimeCellController
    if (!Get.isRegistered<TimeCellController>()) {
      Get.put(TimeCellController());
    }
    _timeCellController = Get.find<TimeCellController>();
  }

  @override
  @override
  void dispose() {
    super.dispose();
    if (_timeCellController != null) {
      _timeCellController!.dispose();
    }
    if (Get.isRegistered<TimeCellController>()) {
      Get.delete<TimeCellController>();
    }
  }

  // UI Section: Lecture Information
  Widget _buildLectureInfoSection() {
    return CustomContainer(
      headerText: "معلومات الحصة", // Lecture Information
      headerIcon: Icons.person,
      child: Column(
        children: [
          // Lecture Name Inputs
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "اسم الحصة بالعربية", // Lecture Name in Arabic
                  child: CustomTextField(
                    controller: formController.controllers[0],
                    validator: (value) => Validator.notEmptyValidator(
                        value, "يجب إدخال الاسم"), // Must enter the name
                    focusNode: formController.focusNodes[0],
                    onSaved: (p0) => lectureInfo.lecture.lectureNameAr = p0!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle:
                      "اسم الحصة بالإنجليزية", // Lecture Name in English
                  child: CustomTextField(
                    controller: formController.controllers[1],
                    validator: (value) => Validator.notEmptyValidator(
                        value, "يجب إدخال الاسم"), // Must enter the name
                    focusNode: formController.focusNodes[1],
                    onSaved: (p0) => lectureInfo.lecture.lectureNameEn = p0!,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Lecture Type Dropdown
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "نوع الحصة", // Lecture Type
                  child: DropDownWidget<String>(
                    items: type,
                    initialValue: selectedLectureType,
                    onSaved: (p0) => lectureInfo.lecture.circleType =
                        getCircleTypeValue(p0!),
                    onChanged: (p0) {
                      setState(() => selectedLectureType = p0!);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category Dropdown
          Row(
            children: [
              Expanded(
                child: InputField(
                  inputTitle: "الفئة", // Category
                  child: DropDownWidget<String>(
                    items: const ["male", "female", "both"],
                    initialValue: lectureInfo.lecture.category ?? "both",
                    onSaved: (p0) => lectureInfo.lecture.category = p0!,
                    onChanged: (p0) {
                      setState(() => lectureInfo.lecture.category = p0!);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Teachers Multi-Select
          InputField(
            inputTitle: "المعلمون", // Teachers
            child: _buildTeacherMultiSelect(),
          ),
          const SizedBox(height: 8),
          // Show on Website Dropdown
          InputField(
            inputTitle: "عرض على الموقع؟", // Show on Website?
            child: DropDownWidget<bool>(
              items: trueFalse,
              initialValue: showOnWebsite,
              onSaved: (p0) {
                lectureInfo.lecture.shownOnWebsite = transformBool(p0!);
              },
              onChanged: (p0) {
                setState(() => showOnWebsite = p0!);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Teacher Multi-Select Dropdown
  Widget _buildTeacherMultiSelect() {
    final teachers = teacherResult?.items ?? [];
    if (teachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'لا يوجد معلمين متاحين',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected teachers display
          if (selectedTeachers != null &&
              (selectedTeachers?.isNotEmpty ?? false))
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTeachers?.map((teacher) {
                      return Chip(
                        label: Text(
                          teacher.obj.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            selectedTeachers?.remove(teacher);
                            lectureInfo.teachers =
                                selectedTeachers?.map((e) => e.obj).toList() ??
                                    [];
                          });
                        },
                        backgroundColor: Colors.teal.shade100,
                      );
                    }).toList() ??
                    [],
              ),
            ),
          // Dropdown button
          PopupMenuButton<MultiSelectItem<Teacher>>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_drop_down),
                  Text(
                    selectedTeachers == null ||
                            (selectedTeachers?.isEmpty ?? true)
                        ? 'اختر المعلمين'
                        : '${selectedTeachers?.length ?? 0} معلم محدد',
                    style: TextStyle(
                      color: selectedTeachers == null ||
                              (selectedTeachers?.isEmpty ?? true)
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) {
              return (teacherResult?.items ?? []).map((teacher) {
                final isSelected =
                    selectedTeachers?.any((t) => t.id == teacher.id) ?? false;
                return PopupMenuItem<MultiSelectItem<Teacher>>(
                  value: teacher,
                  child: StatefulBuilder(
                    builder: (context, setMenuState) {
                      return CheckboxListTile(
                        title: Text(teacher.obj.toString()),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setMenuState(() {
                            setState(() {
                              if (value == true) {
                                if (selectedTeachers == null) {
                                  selectedTeachers = [];
                                }
                                if (!(selectedTeachers
                                        ?.any((t) => t.id == teacher.id) ??
                                    false)) {
                                  selectedTeachers?.add(teacher);
                                }
                              } else {
                                selectedTeachers
                                    ?.removeWhere((t) => t.id == teacher.id);
                              }
                              lectureInfo.teachers = selectedTeachers
                                      ?.map((e) => e.obj)
                                      .toList() ??
                                  [];
                            });
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  // UI Section: Schedule Information
  Widget _buildScheduleInfoSection() {
    return CustomContainer(
      headerIcon: Icons.alarm,
      headerText: "معلومات الجدول", // Schedule Information
      child: CustomMatrix(
        controller: timeCellController,
      ),
    );
  }

  // Form Builder
  @override
  List<Widget> formChild() {
    return [
      _buildLectureInfoSection(),
      const SizedBox(height: 10),
      _buildScheduleInfoSection(),
      const SizedBox(height: 10),
    ];
  }

  // Form Submission - Completely reimplemented
  @override
  Future<bool> submit() async {
    try {
      // Extract schedules from time matrix controller
      lectureInfo.schedules = timeCellController.getSelectedDays();

      // Validate lecture data
      if (!lectureInfo.isComplete) {
        dev.log('Lecture form is incomplete');
        // Don't show snackbar - return false and let form validation handle it
        return false;
      }

      // Debug logging
      dev.log('=== Lecture Submission ===');
      dev.log('Lecture Info: ${lectureInfo.toJson()}');
      dev.log('Schedules: ${lectureInfo.schedules.length}');
      dev.log('Teachers: ${lectureInfo.teachers.length}');

      // Determine if we're editing or creating
      final isEditing = editController?.model.value != null;
      dev.log('Mode: ${isEditing ? "EDIT" : "CREATE"}');

      if (isEditing) {
        return await _handleEditSubmission();
      } else {
        return await _handleCreateSubmission();
      }
    } catch (e, stackTrace) {
      dev.log('Unexpected error in submit: $e');
      dev.log('Stack trace: $stackTrace');
      // Don't show snackbar here - let the calling context handle it
      return false;
    }
  }

  /// Handle editing an existing lecture
  Future<bool> _handleEditSubmission() async {
    try {
      // Get lecture ID
      final lectureId = editController!.model.value!.lecture.lectureId;
      if (lectureId == null) {
        dev.log('Error: Lecture ID is null');
        return false;
      }

      dev.log('Updating lecture with ID: $lectureId');

      // Get the lecture management controller
      final lectureController = Get.find<LectureManagementController>();

      // CRITICAL: Clear all selections BEFORE making any API calls
      // This prevents stale object references when the list refreshes
      lectureController.deselectAllLectures();
      dev.log('Selections cleared before update');

      // Perform the update WITHOUT showing snackbars (they cause overlay errors)
      await _updateLectureSilently(lectureController, lectureId);

      dev.log('Lecture updated successfully');
      return true;
    } catch (e, stackTrace) {
      dev.log('Error in _handleEditSubmission: $e');
      dev.log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update lecture without showing snackbars (to avoid overlay errors)
  Future<void> _updateLectureSilently(
      LectureManagementController controller, int lectureId) async {
    try {
      controller.isLoading.value = true;
      controller.errorMessage.value = '';

      // Send PUT request - use generic json parser to handle empty responses
      await ApiService.put(
        ApiEndpoints.updateLecture(lectureId),
        lectureInfo.toJson(),
        (json) => json,
      );

      dev.log('API call successful, refreshing list');

      // Refresh the list to get updated data
      await controller.fetchAllLectures();
    } catch (e) {
      controller.errorMessage.value = 'فشل تحديث الحلقة';
      dev.log('Error updating lecture: $e');
      rethrow;
    } finally {
      controller.isLoading.value = false;
    }
  }

  /// Handle creating a new lecture
  Future<bool> _handleCreateSubmission() async {
    try {
      dev.log('Creating new lecture');

      // Use the existing submit form helper
      final success = await submitForm<LectureForm>(
        formKey,
        lectureInfo,
        ApiEndpoints.submitLectureForm,
        LectureForm.fromJson,
      );

      if (success) {
        dev.log('Lecture created successfully');

        // Refresh the lecture list if controller exists
        if (Get.isRegistered<LectureManagementController>()) {
          final lectureController = Get.find<LectureManagementController>();
          await lectureController.fetchAllLectures();
        }
      }

      return success;
    } catch (e, stackTrace) {
      dev.log('Error in _handleCreateSubmission: $e');
      dev.log('Stack trace: $stackTrace');

      Get.snackbar('خطأ', 'فشل إنشاء الحلقة');
      return false;
    }
  }

  // Default Values Setup
  @override
  void setDefaultFieldsValue() {
    final s = editController!.model.value!;
    formController.controllers[0].text = s.lecture.lectureNameAr ?? "";
    formController.controllers[1].text = s.lecture.lectureNameEn ?? "";

    // Copy the complete lecture data to lectureInfo
    lectureInfo.lecture.lectureId = s.lecture.lectureId;
    lectureInfo.lecture.lectureNameAr = s.lecture.lectureNameAr;
    lectureInfo.lecture.lectureNameEn = s.lecture.lectureNameEn;
    lectureInfo.lecture.circleType = s.lecture.circleType;
    lectureInfo.lecture.category = s.lecture.category ?? "both";
    lectureInfo.lecture.shownOnWebsite = s.lecture.shownOnWebsite;

    // Convert English backend value to Arabic UI text
    final arabicType = getCircleTypeText(s.lecture.circleType);
    if (type.contains(arabicType)) {
      selectedLectureType = arabicType;
    } else {
      selectedLectureType = type.isNotEmpty ? type[0] : '';
    }
    showOnWebsite = s.lecture.shownOnWebsite;

    if (teacherResult != null &&
        editController!.model.value?.teachers != null) {
      // Get the teacher IDs from the lecture being edited
      final existingTeacherIds =
          editController!.model.value!.teachers.map((t) => t.teacherId).toSet();

      // Find matching teachers from the available list
      selectedTeachers = (teacherResult?.items ?? [])
          .where(
              (element) => existingTeacherIds.contains(element.obj.teacherId))
          .toList();

      // Update lectureInfo with the selected teachers
      lectureInfo.teachers = selectedTeachers?.map((e) => e.obj).toList() ?? [];
    }

    // Load existing schedules into the time matrix
    // Ensure the controller is initialized before using it
    if (s.schedules.isNotEmpty) {
      timeCellController.loadSchedules(s.schedules);
    }
  }
}
