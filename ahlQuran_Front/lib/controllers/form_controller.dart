import 'package:get/get.dart';
import 'package:flutter/material.dart';

class FormController extends GetxController {
  final int fieldCount;
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  FormController(this.fieldCount) {
    controllers = List.generate(fieldCount, (index) => TextEditingController());
    focusNodes = List.generate(fieldCount, (index) => FocusNode());
  }

  @override
  void onClose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.onClose();
  }

  void moveToFirstEmptyField(GlobalKey<FormState> formKey) {
    if (!formKey.currentState!.validate()) {
      for (int i = 0; i < controllers.length; i++) {
        if (controllers[i].text.isEmpty) {
          focusNodes[i].requestFocus();
          return;
        }
      }
    }
  }
}
