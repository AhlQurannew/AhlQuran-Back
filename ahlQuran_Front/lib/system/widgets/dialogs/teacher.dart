import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import '../custom_container.dart';
import '../input_field.dart';
import '../../new_models/forms/teacher_form.dart';
import '../../../controllers/generate.dart';
import '../../../controllers/validator.dart';
import '../../../system/services/network/api_endpoints.dart';

class TeacherDialog extends GlobalDialog {
  const TeacherDialog({
    super.key,
    super.dialogHeader = "إضافة معلم",
    super.numberInputs = 5,
  });

  @override
  State<GlobalDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState<GEC extends GenericEditController<TeacherInfoDialog>>
    extends DialogState<GEC> {
  late Generate generate;
  var teacherInfo = TeacherInfoDialog();

  @override
  void initState() {
    super.initState();
    generate = Get.isRegistered<Generate>()
        ? Get.find<Generate>()
        : Get.put(Generate());
    formController.controllers[4].text = generate.generatePassword();

    if (editController?.model.value != null) {
      // In edit mode, use the original reference - no deep copy needed
      teacherInfo = editController!.model.value!;
    } else {
      teacherInfo.accountInfo.accountType = "teacher";
    }
  }

  @override
  void dispose() {
    generate.dispose();
    Get.delete<Generate>();
    super.dispose();
  }

  @override
  List<Widget> formChild() {
    return [
      _buildTeacherSection(),
      const SizedBox(height: 10),
      if (editController?.model.value == null) _buildAccountSection(),
    ];
  }

  Widget _buildTeacherSection() {
    return CustomContainer(
      headerText: "معلومات المعلم",
      headerIcon: Icons.person,
      child: Column(
        children: [
          _buildNameRow(),
          const SizedBox(height: 8),
          _buildEmailAndRiwayaRow(),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "الاسم الأول",
            child: CustomTextField(
              controller: formController.controllers[0],
              validator: (value) =>
                  Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
              focusNode: formController.focusNodes[0],
              onSaved: (p0) => teacherInfo.firstName = p0!,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "اسم العائلة",
            child: CustomTextField(
              controller: formController.controllers[1],
              validator: (value) =>
                  Validator.notEmptyValidator(value, "يجب إدخال الاسم"),
              focusNode: formController.focusNodes[1],
              onSaved: (p0) => teacherInfo.lastName = p0!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailAndRiwayaRow() {
    return Row(
      children: [
        Expanded(
          child: InputField(
            inputTitle: "البريد الإلكتروني",
            child: CustomTextField(
              controller: formController.controllers[2],
              validator: (value) => Validator.isValidEmail(value),
              focusNode: formController.focusNodes[2],
              onSaved: (p0) => teacherInfo.email = p0!,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "الرواية",
            child: CustomTextField(
              controller: formController.controllers[3],
              validator: (value) =>
                  Validator.notEmptyValidator(value, "يجب إدخال الرواية"),
              focusNode: formController.focusNodes[3],
              onSaved: (p0) => teacherInfo.riwaya = p0!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return CustomContainer(
      headerIcon: Icons.account_box,
      headerText: "معلومات الحساب",
      child: Row(
        children: [
          Expanded(
            child: InputField(
              inputTitle: "كلمة المرور",
              child: CustomTextField(
                controller: formController.controllers[4],
                onSaved: (p0) => teacherInfo.accountInfo.passcode = p0!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void setDefaultFieldsValue() {
    final t = editController?.model.value;
    formController.controllers[0].text = t?.firstName ?? '';
    formController.controllers[1].text = t?.lastName ?? '';
    formController.controllers[2].text = t?.email ?? '';
    formController.controllers[3].text = t?.riwaya ?? '';
    if (editController?.model.value == null) {
      formController.controllers[4].text = generate.generatePassword();
    }
  }

  @override
  Future<void> loadData() => Future(() {});

  @override
  Future<bool> submit() async {
    debugPrint('=== TEACHER SUBMIT START ===');
    debugPrint('Edit mode: ${editController?.model.value != null}');
    debugPrint('Teacher ID: ${teacherInfo.teacherId}');

    if (!formKey.currentState!.validate()) return false;
    formKey.currentState!.save();

    try {
      if (editController?.model.value == null) {
        // Create mode
        final body = {
          'firstname': teacherInfo.firstName,
          'lastname': teacherInfo.lastName,
          'email': teacherInfo.email,
          'riwaya': teacherInfo.riwaya,
          'password': teacherInfo.accountInfo.passcode,
        };

        await ApiService.post(
          ApiEndpoints.getTeachers,
          body,
          (json) => json,
        );

        debugPrint('✅ Teacher created successfully');
        return true;
      } else {
        // Edit mode
        final teacherId = teacherInfo.teacherId;
        if (teacherId == null) {
          debugPrint('❌ Error: Teacher ID is null');
          return false;
        }

        debugPrint('Updating teacher ID: $teacherId');
        final body = {
          'firstname': teacherInfo.firstName,
          'lastname': teacherInfo.lastName,
          'email': teacherInfo.email,
          'riwaya': teacherInfo.riwaya,
        };

        debugPrint('PUT body: $body');
        final response = await ApiService.put(
          ApiEndpoints.getTeacherById(teacherId),
          body,
          (json) => json,
        );

        debugPrint('✅ Teacher updated successfully');
        debugPrint('Response: $response');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error submitting teacher: $e');
      return false;
    }
  }
}
