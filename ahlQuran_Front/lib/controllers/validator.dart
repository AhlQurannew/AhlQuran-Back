import 'package:flutter/material.dart';

class Validator {
  static String? isValidEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "يجب ادخال ايميل";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "من فضلك ادخل ايميل صحيح";
    }
    return null;
  }

  static String? isValidPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يجب ادخال رقم الواتساب';
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return "من فضلك ادخل رقم هاتف صحيح";
    }
    return null;
  }

  static String? notEmptyValidator(String? value, String errorText) {
    if (value == null || value.isEmpty) {
      return errorText;
    }
    return null;
  }

  bool validateForm(GlobalKey<FormState> formKey) {
    if (formKey.currentState != null && formKey.currentState!.validate()) {
      return true;
    } else {
      return false;
    }
  }
}
