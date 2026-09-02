import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/submit_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/date_picker.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/exam_records_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/personal_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/custom_container.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/input_field.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/multiselect.dart';

class ExamRecordsDialog<GEC extends GenericEditController<ExamRecordInfoDialog>>
    extends GlobalDialog {
  const ExamRecordsDialog(
      {super.key, super.dialogHeader = "إضافة اختبار", super.numberInputs = 7});

  @override
  State<GlobalDialog> createState() =>
      _LectureDialogState<GenericEditController<ExamRecordInfoDialog>>();
}

class _LectureDialogState<
        GEC extends GenericEditController<ExamRecordInfoDialog>>
    extends DialogState<GEC> {
  final examRecoInfoDialog = ExamRecordInfoDialog();
  MultiSelectResult<Exam>? examsList;
  MultiSelectResult<PersonalInfo>? studentProfilesList;
  final Rx<String?> examDate = "اختر التاريخ".obs;

  @override
  List<Widget> formChild() {
    return [
      // Student
      CustomContainer(
        headerIcon: Icons.family_restroom,
        headerText: "معلومات عن الطالب",
        child: Row(children: [
          Expanded(
            child: InputField(
              inputTitle: "الطالب",
              child: MultiSelect<PersonalInfo>(
                getPickedItems: (pickedItems) {
                  if (pickedItems.isNotEmpty) {
                    examRecoInfoDialog.personalInfo = pickedItems[0].obj;
                  }
                },
                initialPickedItems:
                    editController?.model.value?.personalInfo != null
                        ? [
                            MultiSelectItem<PersonalInfo>(
                              id: editController!
                                  .model.value!.personalInfo.studentId,
                              obj: editController!.model.value!.personalInfo,
                              name: editController!.model.value!.personalInfo
                                  .toString(),
                            )
                          ]
                        : [],
                preparedData: studentProfilesList?.items ?? [],
                hintText: "البحث عن الطالب",
                maxSelectedItems: 1,
              ),
            ),
          ),
        ]),
      ),

      CustomContainer(
        headerIcon: Icons.settings,
        headerText: "معلومات عن الامتحان",
        child: Column(children: [
          Row(
            children: [
              Expanded(
                  child: InputField(
                      inputTitle: "الاسم الامتحان",
                      child: MultiSelect<Exam>(
                        getPickedItems: (pickedItems) {
                          if (pickedItems.isNotEmpty) {
                            examRecoInfoDialog.exam = pickedItems[0].obj;
                          }
                        },
                        initialPickedItems: editController
                                    ?.model.value?.personalInfo !=
                                null
                            ? [
                                MultiSelectItem<Exam>(
                                  id: editController!.model.value!.exam.examId,
                                  obj: editController!.model.value!.exam,
                                  name: editController!.model.value!.exam
                                      .toString(),
                                )
                              ]
                            : [],
                        preparedData: examsList?.items ?? [],
                        hintText: "البحث عن الامتحان",
                        maxSelectedItems: 1,
                      )))
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: InputField(
                inputTitle: "تاريخ الامتحان",
                child: Obx(() => OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      onPressed: () async {
                        final date = await showCustomDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final dateStr =
                              "${date.year}-${date.month}-${date.day}";
                          examDate.value = dateStr;
                          examRecoInfoDialog.examStudent.dateTakeExam = dateStr;
                        }
                      },
                      child: Text(examDate.value ?? "اختر التاريخ"),
                    )),
              ),
            ),
          ]),
        ]),
      ),

      // Exam Date
      CustomContainer(
        headerIcon: Icons.note,
        headerText: "نتائج الامتحان",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points
            Row(children: [
              Expanded(
                child: InputField(
                  inputTitle: "نقطة الحفظ",
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    controller: formController.controllers[0],
                    onSaved: (v) =>
                        examRecoInfoDialog.examStudent.pointHifd = v,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "تجويد تطبيقي",
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    controller: formController.controllers[1],
                    onSaved: (v) => examRecoInfoDialog
                        .examStudent.pointTajwidApplicative = v,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InputField(
                  inputTitle: "تجويد نظري",
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        examRecoInfoDialog.examStudent.pointTajwidTheoric = v,
                    controller: formController.controllers[2],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "الآداء",
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        examRecoInfoDialog.examStudent.pointPerformance = v,
                    controller: formController.controllers[3],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InputField(
                  inputTitle: "خصم تأديبي",
                  child: CustomTextField(
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        examRecoInfoDialog.examStudent.pointDeductionTal = v,
                    controller: formController.controllers[4],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  inputTitle: "خصم تنبيهي",
                  child: CustomTextField(
                    controller: formController.controllers[5],
                    keyboardType: TextInputType.number,
                    onSaved: (v) => examRecoInfoDialog
                        .examStudent.pointDeductionTanbihi = v,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InputField(
                  inputTitle: "خصم تجويدي",
                  child: CustomTextField(
                    controller: formController.controllers[6],
                    keyboardType: TextInputType.number,
                    onSaved: (v) => examRecoInfoDialog
                        .examStudent.pointDeductionTajwidi = v,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ];
  }

  @override
  Future<void> loadData() async {
    try {
      final fetchedExams =
          await getItems<Exam>(ApiEndpoints.getExams, Exam.fromJson);
      final fetchedStudents = await getItems<PersonalInfo>(
          ApiEndpoints.getPersonalInfos, PersonalInfo.fromJson);
      dev.log('teacherNames: ${fetchedExams.toString()}');

      super.setState(() {
        examsList = fetchedExams;
        studentProfilesList = fetchedStudents;
      });
    } catch (e) {
      dev.log("Error loading data: $e");
    }
  }

  @override
  Future<bool> submit() async {
    return super.editController!.model.value == null
        ? await submitForm<ExamRecordInfoDialog>(formKey, examRecoInfoDialog,
            ApiEndpoints.submitSpecialExamRecord, ExamRecordInfoDialog.fromJson)
        : await submitEditDataForm<ExamRecordInfoDialog>(
            formKey,
            examRecoInfoDialog,
            ApiEndpoints.getSpecialExamRecordsById(
                editController!.model.value?.exam.examId ?? -1),
            ExamRecordInfoDialog.fromJson);
  }

  @override
  void setDefaultFieldsValue() {
    final model = editController?.model.value;
    if (model != null) {
      // Set student
      examRecoInfoDialog.personalInfo = model.personalInfo;
      // Set exam
      examRecoInfoDialog.exam = model.exam;
      // Set exam date
      if (model.examStudent.dateTakeExam != null) {
        examDate.value = model.examStudent.dateTakeExam;
        examRecoInfoDialog.examStudent.dateTakeExam =
            model.examStudent.dateTakeExam;
      }
      // Set points
      formController.controllers[0].text =
          model.examStudent.pointHifd.toString();
      formController.controllers[1].text =
          model.examStudent.pointTajwidApplicative.toString();
      formController.controllers[2].text =
          model.examStudent.pointTajwidTheoric.toString();
      formController.controllers[3].text =
          model.examStudent.pointPerformance.toString();
      formController.controllers[4].text =
          model.examStudent.pointDeductionTal.toString();
      formController.controllers[5].text =
          model.examStudent.pointDeductionTanbihi.toString();
      formController.controllers[6].text =
          model.examStudent.pointDeductionTajwidi.toString();
    }
  }
}
