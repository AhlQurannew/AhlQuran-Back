import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/submit_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/exam_teachers_from.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/custom_container.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/input_field.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/multiselect.dart';

class ExamTeachersDialog extends GlobalDialog {
  const ExamTeachersDialog(
      {super.key,
      super.dialogHeader = "إضافة اختبار",
      super.numberInputs = 10});

  @override
  State<GlobalDialog> createState() =>
      _ExamTeachersDialogState<GenericEditController<ExamTeacherInfoDialog>>();
}

class _ExamTeachersDialogState<
        GEC extends GenericEditController<ExamTeacherInfoDialog>>
    extends DialogState<GEC> {
  final lectureInfo = ExamTeacherInfoDialog();
  MultiSelectResult<Teacher>? teacherResult;
  MultiSelectResult<Exam>? examsList;
  final Rx<String?> examDate = "اختر التاريخ".obs;

  @override
  Future<void> loadData() async {
    try {
      final fetchedExams =
          await getItems<Exam>(ApiEndpoints.getExams, Exam.fromJson);
      final fetchedTeachernNames =
          await getItems<Teacher>(ApiEndpoints.getTeachers, Teacher.fromJson);

      dev.log('teacherNames: ${fetchedTeachernNames.toString()}');

      setState(() {
        teacherResult = fetchedTeachernNames;
        examsList = fetchedExams;
      });
    } catch (e) {
      dev.log("Error loading data: $e");
    }
  }

  @override
  List<Widget> formChild() {
    return [
      // Teacher Dropdown
      CustomContainer(
        headerIcon: Icons.family_restroom,
        headerText: "معلومات عن المعلم",
        child: Row(children: [
          Expanded(
            child: InputField(
              inputTitle: "المعلم",
              child: MultiSelect<Teacher>(
                getPickedItems: (pickedItems) {
                  if (pickedItems.isNotEmpty) {
                    lectureInfo.techer = pickedItems[0].obj;
                  }
                },
                preparedData: teacherResult?.items ?? [],
                hintText: "البحث عن المعلم",
                maxSelectedItems: 1,
              ),
            ),
          ),
        ]),
      ),

      CustomContainer(
        headerIcon: Icons.settings,
        headerText: "معلومات عن الامتحان",
        child: Row(
          children: [
            Expanded(
                child: InputField(
                    inputTitle: "الاسم الامتحان",
                    child: MultiSelect<Exam>(
                      getPickedItems: (pickedItems) {
                        if (pickedItems.isNotEmpty) {
                          lectureInfo.exam =
                              pickedItems.map((e) => e.obj).toList();
                        }
                      },
                      preparedData: examsList?.items ?? [],
                      hintText: "البحث عن الامتحان",
                      maxSelectedItems: null,
                    )))
          ],
        ),
      ),
    ];
  }

  @override
  Future<bool> submit() async {
    return editController!.model.value == null
        ? await submitForm<ExamTeacherInfoDialog>(formKey, lectureInfo,
            ApiEndpoints.submitLectureForm, (ExamTeacherInfoDialog.fromJson))
        : await submitEditDataForm<ExamTeacherInfoDialog>(
            formKey,
            lectureInfo,
            ApiEndpoints.getSpecialLecture(
                editController!.model.value!.exam.first.examId),
            (ExamTeacherInfoDialog.fromJson));
  }

  @override
  void setDefaultFieldsValue() {
    final model = editController?.model.value;
    if (model == null) return;

    lectureInfo.techer = model.techer;
  }
}
