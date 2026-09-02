import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'auth_layout.dart';

class CreateAccountScreen extends StatelessWidget {
  CreateAccountScreen({super.key});

  final AuthController controller = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();
  final _confirmPasswordController = TextEditingController();

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Check if it matches the pattern: starts with 0, followed by 9 digits
    final phoneRegex = RegExp(r'^0\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'رقم الهاتف يجب أن يبدأ بـ 0 ويتبعه 9 أرقام';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconTheme = Theme.of(context).iconTheme;

    return AuthLayout(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "إنشاء حساب جديد",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.firstnameController,
                decoration: InputDecoration(
                  hintText: "الاسم الأول",
                  prefixIcon:
                      Icon(Icons.person_outline, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الاسم الأول مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.lastnameController,
                decoration: InputDecoration(
                  hintText: "اسم العائلة",
                  prefixIcon:
                      Icon(Icons.person_outline, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم العائلة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "البريد الإلكتروني",
                  prefixIcon:
                      Icon(Icons.email_outlined, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "كلمة المرور",
                  prefixIcon: Icon(Icons.lock_outline, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'كلمة المرور مطلوبة';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "تأكيد كلمة المرور",
                  prefixIcon: Icon(Icons.lock_outline, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'تأكيد كلمة المرور مطلوب';
                  }
                  if (value != controller.passwordController.text) {
                    return 'كلمة المرور غير متطابقة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.schoolNameController,
                decoration: InputDecoration(
                  hintText: "اسم المدرسة",
                  prefixIcon:
                      Icon(Icons.school_outlined, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم المدرسة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: "رقم الهاتف",
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: iconTheme.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    controller.signup();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                child: Text(
                  "إنشاء حساب",
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
