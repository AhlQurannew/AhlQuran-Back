import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/submit_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/appreciation.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/dialog.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/input_field.dart';

class AppreciationDialog extends GlobalDialog {
  const AppreciationDialog(
      {super.key, super.dialogHeader = "إضافة تقدير", super.numberInputs = 3});

  @override
  State<GlobalDialog> createState() => _AppreciationDialogState();
}

class _AppreciationDialogState<GEC extends GenericEditController<Appreciation>>
    extends DialogState<GEC> {
  Appreciation appreciation = Appreciation();

  @override
  List<Widget> formChild() {
    return [
      Row(children: [
        Expanded(
          child: InputField(
            inputTitle: "من",
            child: CustomTextField(
              controller: formController.controllers[0],
              onSaved: (p0) => appreciation.pointMin = p0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputField(
            inputTitle: "إلى",
            child: CustomTextField(
              controller: formController.controllers[1],
              onSaved: (p0) => appreciation.pointMax = p0,
            ),
          ),
        )
      ]),
      Row(children: [
        Expanded(
          child: InputField(
            inputTitle: "التقدير",
            child: CustomTextField(
              controller: formController.controllers[2],
              onSaved: (p0) => appreciation.note = p0,
            ),
          ),
        )
      ]),
    ];
  }

  @override
  Future<void> loadData() {
    return Future(() {});
  }

  @override
  void setDefaultFieldsValue() {
    final s = editController?.model.value;
    formController.controllers[0].text = s?.pointMin.toString() ?? '';
    formController.controllers[1].text = s?.pointMax.toString() ?? '';
    formController.controllers[2].text = s?.note ?? '';
    appreciation = editController?.model.value ?? Appreciation();
  }

  @override
  Future<bool> submit() async {
    return super.editController?.model.value == null
        ? await submitForm<Appreciation>(
            formKey,
            appreciation,
            ApiEndpoints.getAppreciations,
            Appreciation.fromJson,
          )
        : await submitEditDataForm<Appreciation>(
            formKey,
            appreciation,
            ApiEndpoints.getAppreciationById(
                editController?.model.value?.appreciationId ?? -1),
            Appreciation.fromJson,
          );
  }
}
