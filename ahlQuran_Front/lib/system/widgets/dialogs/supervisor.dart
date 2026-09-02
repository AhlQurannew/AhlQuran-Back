import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/supervisor.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/common/dialog_header.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/common/dialog_submit_button.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/input_field.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/utils/snackbar_helper.dart';

class SupervisorDialog extends StatefulWidget {
  final String dialogHeader;

  const SupervisorDialog({
    super.key,
    required this.dialogHeader,
  });

  @override
  State<SupervisorDialog> createState() => _SupervisorDialogState();
}

class _SupervisorDialogState extends State<SupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final RxBool _isPasswordVisible = false.obs;
  final RxBool _isComplete = false.obs;

  bool get isEditMode {
    return Get.isRegistered<GenericEditController<Supervisor>>();
  }

  Supervisor? get existingSupervisor {
    if (isEditMode) {
      return Get.find<GenericEditController<Supervisor>>().model.value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _firstnameController =
        TextEditingController(text: existingSupervisor?.firstname ?? '');
    _lastnameController =
        TextEditingController(text: existingSupervisor?.lastname ?? '');
    _emailController =
        TextEditingController(text: existingSupervisor?.email ?? '');
    _passwordController = TextEditingController();

    _firstnameController.addListener(_checkComplete);
    _lastnameController.addListener(_checkComplete);
    _emailController.addListener(_checkComplete);
    _passwordController.addListener(_checkComplete);

    _checkComplete();
  }

  void _checkComplete() {
    final hasFirstname = _firstnameController.text.trim().isNotEmpty;
    final hasLastname = _lastnameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty &&
        GetUtils.isEmail(_emailController.text.trim());
    final hasPassword = isEditMode || _passwordController.text.length >= 6;

    _isComplete.value = hasFirstname && hasLastname && hasEmail && hasPassword;
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final body = {
        'firstname': _firstnameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        body['password'] = _passwordController.text;
      }

      if (isEditMode) {
        await ApiService.put(
          ApiEndpoints.getSupervisorById(existingSupervisor!.id!),
          body,
          (json) => json,
        );
      } else {
        await ApiService.post(
          ApiEndpoints.getSupervisors,
          body,
          (json) => json,
        );
      }

      Get.back(result: true);
    } catch (e) {
      Get.back(result: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExit();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DialogHeader(
                  title: widget.dialogHeader,
                  onClose: _handleExit,
                ),
                const SizedBox(height: 24),

                // First Name
                InputField(
                  inputTitle: 'الاسم الأول',
                  child: CustomTextField(
                    controller: _firstnameController,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الاسم الأول';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Last Name
                InputField(
                  inputTitle: 'الاسم الأخير',
                  child: CustomTextField(
                    controller: _lastnameController,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الاسم الأخير';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                InputField(
                  inputTitle: 'البريد الإلكتروني',
                  child: CustomTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) {},
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!GetUtils.isEmail(value.trim())) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                Obx(() => InputField(
                      inputTitle:
                          isEditMode ? 'كلمة المرور (اختياري)' : 'كلمة المرور',
                      child: CustomTextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible.value,
                        onSaved: (value) {},
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => _isPasswordVisible.value =
                              !_isPasswordVisible.value,
                        ),
                        validator: (value) {
                          if (!isEditMode && (value == null || value.isEmpty)) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                    )),
                const SizedBox(height: 24),

                // Submit Button
                DialogSubmitButton(
                  isComplete: _isComplete,
                  onSubmit: _handleSubmit,
                  isEditMode: isEditMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleExit() {
    Get.back(result: false);
    showInfoSnackbar('تم إلغاء العملية');
  }
}
