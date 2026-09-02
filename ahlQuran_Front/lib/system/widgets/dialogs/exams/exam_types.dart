import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/submit_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/validator.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/const/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/drop_down.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/input_field.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/multiselect.dart';

class ExamTypesDialog extends GlobalDialog {
  const ExamTypesDialog(
      {super.key, super.dialogHeader = "إضافة اختبار", super.numberInputs = 8});

  @override
  State<GlobalDialog> createState() =>
      _ExamTypesDialogState<GenericEditController<Exam>>();
}

class _ExamTypesDialogState<GEC extends GenericEditController<Exam>>
    extends DialogState<GEC> {
  @override
  Future<void> loadData() async {
    try {
      final fetchedTeachernNames =
          await getItems<Teacher>(ApiEndpoints.getTeachers, Teacher.fromJson);

      dev.log('teacherNames: ${fetchedTeachernNames.toString()}');

      setState(() {
        teacherResult = fetchedTeachernNames;
        dev.log('teacherNames: ${teacherResult.toString()}');
      });
    } catch (e) {
      dev.log("Error loading data: $e");
    }
  }

  Exam exam = Exam();
  MultiSelectResult<Teacher>? teacherResult;

  Widget _numericField(String title, int controllerIndex) {
    return InputField(
      inputTitle: title,
      child: CustomTextField(
        controller: formController.controllers[controllerIndex],
        keyboardType: TextInputType.number,
        onSaved: (v) {
          switch (controllerIndex) {
            case 2:
              exam.examMaxPoint = double.tryParse(v ?? '') ?? 0;
              break;
            case 3:
              exam.examSucessMinPoint = double.tryParse(v ?? '') ?? 0;
              break;
            case 4:
              exam.examMemoPoint = double.tryParse(v ?? '') ?? 0;
              break;
            case 5:
              exam.examTjwidAppPoint = double.tryParse(v ?? '') ?? 0;
              break;
            case 6:
              exam.examTjwidThoPoint = double.tryParse(v ?? '') ?? 0;
              break;
            case 7:
              exam.examPerformancePoint = double.tryParse(v ?? '') ?? 0;
              break;
          }
        },
      ),
    );
  }

  @override
  List<Widget> formChild() {
    return [
      Row(children: [
        Expanded(
          child: InputField(
            inputTitle: "اسم الاختبار",
            child: CustomTextField(
              controller: formController.controllers[0],
              validator: (v) => Validator.notEmptyValidator(v, "الاسم مطلوب"),
              onSaved: (v) => exam.examNameAr = v!,
            ),
          ),
        ),
      ]),
      Row(children: [
        Expanded(
          child: InputField(
            inputTitle: "(en) اسم الاختبار",
            child: CustomTextField(
              controller: formController.controllers[1],
              validator: (v) => Validator.notEmptyValidator(v, "الاسم مطلوب"),
              onSaved: (v) => exam.examNameEn = v!,
            ),
          ),
        ),
      ]),
      Row(children: [
        Expanded(
          child: InputField(
            inputTitle: "نوع الاختبار",
            child: DropDownWidget<String>(
              items: examTypes, // You define this list
              initialValue: examTypes[0],
              onSaved: (v) => exam.examType = v!,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ]),
      Row(children: [
        Expanded(child: _numericField("الدرجة العظمى", 2)),
        const SizedBox(width: 8),
        Expanded(child: _numericField("علامة النجاح", 3)),
      ]),
      Row(children: [
        Expanded(child: _numericField("درجة الحفظ", 4)),
        const SizedBox(width: 8),
        Expanded(child: _numericField("درجة التجويد التطبيقي", 5)),
      ]),
      Row(children: [
        Expanded(child: _numericField("درجة التجويد النظري", 6)),
        const SizedBox(width: 8),
        Expanded(child: _numericField("درجة الأداء", 7)),
      ]),
    ];
  }

  @override
  void setDefaultFieldsValue() {
    final s = editController?.model.value;
    formController.controllers[0].text = s?.examNameAr ?? '';
    formController.controllers[1].text = s?.examNameEn ?? '';
    formController.controllers[2].text = s?.examMaxPoint?.toString() ?? '';
    formController.controllers[3].text =
        s?.examSucessMinPoint?.toString() ?? '';
    formController.controllers[4].text = s?.examMemoPoint?.toString() ?? '';
    formController.controllers[5].text = s?.examTjwidAppPoint?.toString() ?? '';
    formController.controllers[6].text = s?.examTjwidThoPoint?.toString() ?? '';
    formController.controllers[7].text =
        s?.examPerformancePoint?.toString() ?? '';

    exam = editController?.model.value ?? Exam();
  }

  @override
  Future<bool> submit() async {
    exam.examLevelId = 1; // todo ;
    return editController!.model.value == null
        ? await submitForm<Exam>(
            formKey, exam, ApiEndpoints.getExams, (Exam.fromJson))
        : await submitEditDataForm<Exam>(
            formKey,
            exam,
            ApiEndpoints.getExamById(editController?.model.value!.examId),
            (Exam.fromJson));
  }
}
