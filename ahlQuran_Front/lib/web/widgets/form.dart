import 'package:flutter/material.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/copy.dart';
import '../../controllers/validator.dart';
import '../../controllers/form_controller.dart' as form;
import '../../system/widgets/custom_checkbox.dart';
import '/system/utils/const/form.dart';
import 'dart:developer' as dev;

class CustomFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const CustomFormWidget({super.key, required this.formKey});

  @override
  State<CustomFormWidget> createState() => _CustomFormWidgetState();
}

class _CustomFormWidgetState extends State<CustomFormWidget> {
  late form.FormController formcontroller;
  Copy copy = Copy();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    formcontroller = Get.find<form.FormController>(tag: "copyPage");
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text('معلومات المدرسة و المشرف'),
          Form(
            key: widget.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //1
                const LabeledText(text: 'اسم المدرسة'),
                TextFormField(
                  controller: formcontroller.controllers[0],
                  focusNode: formcontroller.focusNodes[0],
                  keyboardType: TextInputType.name,
                  validator: (value) => Validator.notEmptyValidator(
                      value, 'يجب ادخال اسم المدرسة'),
                  textAlign: TextAlign.right,
                  onSaved: (newValue) => copy.schoolName = newValue,
                ),

                //2
                const LabeledText(text: 'البلد'),
                DropdownFlutter<String>.search(
                  items: countries,
                  initialItem: countries[1],
                  onChanged: (value) {
                    copy.country = value;
                    dev.log(copy.country.toString());
                  },
                ),

                //3
                const LabeledText(text: 'عنوان المدرسة'),
                TextFormField(
                  controller: formcontroller.controllers[1],
                  focusNode: formcontroller.focusNodes[1],
                  keyboardType: TextInputType.name,
                  validator: (value) => Validator.notEmptyValidator(
                      value, 'يجب ادخال عنوان المدرسة'),
                  textAlign: TextAlign.right,
                  onSaved: (newValue) => copy.schoolAddress = newValue,
                ),

                //4, 5
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const LabeledText(text: 'الكنية'),
                          TextFormField(
                            controller: formcontroller.controllers[3],
                            focusNode: formcontroller.focusNodes[3],
                            keyboardType: TextInputType.name,
                            validator: (value) => Validator.notEmptyValidator(
                                value, 'يجب ادخال الكنية'),
                            textAlign: TextAlign.right,
                            onSaved: (newValue) => copy.name = newValue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          const LabeledText(text: 'اسم المشرف'),
                          TextFormField(
                            controller: formcontroller.controllers[2],
                            focusNode: formcontroller.focusNodes[2],
                            keyboardType: TextInputType.name,
                            validator: (value) => Validator.notEmptyValidator(
                                value, 'يجب ادخال اسم المشرف'),
                            textAlign: TextAlign.right,
                            onSaved: (newValue) =>
                                copy.supervisorName = newValue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //6, 7
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const LabeledText(text: 'رقم الواتساب مع رمز الدولة'),
                          TextFormField(
                            controller: formcontroller.controllers[5],
                            focusNode: formcontroller.focusNodes[5],
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => Validator.isValidPhoneNumber(
                                formcontroller.controllers[5].text),
                            textAlign: TextAlign.right,
                            onSaved: (newValue) => copy.phoneNumber = newValue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          const LabeledText(text: 'البريد الالكتروني'),
                          TextFormField(
                            controller: formcontroller.controllers[4],
                            focusNode: formcontroller.focusNodes[4],
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => Validator.isValidEmail(
                                formcontroller.controllers[4].text),
                            textAlign: TextAlign.right,
                            onSaved: (newValue) => copy.email = newValue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Checkboxes
                CheckboxFormField(
                  text: 'الشروط والاحكام',
                  errorText: 'يجب الموافقة على الشروط',
                ),

                CheckboxFormField(
                  text: 'سياسة الخصوصية',
                  errorText: 'يجب الموافقة على سياسة الخصوصية',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledText extends StatelessWidget {
  final String text;
  const LabeledText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text.rich(
        textAlign: TextAlign.left,
        textDirection: TextDirection.rtl,
        TextSpan(text: text, children: const [
          TextSpan(
              text: '*',
              style: TextStyle(
                color: Colors.red,
              )),
        ]),
      ),
    );
  }
}
