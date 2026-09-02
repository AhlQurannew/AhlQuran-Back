import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import './auth_layout.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconTheme = Theme.of(context).iconTheme;
    final authController = Get.find<AuthController>();

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "تسجيل الدخول",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final isAdmin = authController.selectedRole.value == 'admin';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? "اسم المستخدم" : "البريد الإلكتروني",
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: authController.usernameController,
                    keyboardType: isAdmin
                        ? TextInputType.text
                        : TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isAdmin
                            ? 'يرجى إدخال اسم المستخدم'
                            : 'يرجى إدخال البريد الإلكتروني';
                      }
                      // Only validate email format for non-admin roles
                      if (!isAdmin && !GetUtils.isEmail(value.trim())) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: isAdmin ? "اسم المستخدم" : "البريد الإلكتروني",
                      prefixIcon: Icon(
                        isAdmin ? Icons.person_outline : Icons.email_outlined,
                        color: iconTheme.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Text("كلمة المرور", style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Obx(() => TextFormField(
                  controller: authController.passwordController,
                  obscureText: !authController.isPasswordVisible.value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "ادخل كلمة المرور",
                    prefixIcon:
                        Icon(Icons.lock_outline, color: iconTheme.color),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.isPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: iconTheme.color,
                      ),
                      onPressed: authController.togglePasswordVisibility,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Text("نوع الحساب", style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Obx(() => DropdownButtonFormField<String>(
                  value: authController.selectedRole.value,
                  decoration: InputDecoration(
                    hintText: "اختر نوع الحساب",
                    prefixIcon:
                        Icon(Icons.person_outline, color: iconTheme.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: "admin", child: Text("مسير")),
                    const DropdownMenuItem(
                        value: "president", child: Text("المشرف العام")),
                    const DropdownMenuItem(
                        value: "supervisor", child: Text("مشرف")),
                    const DropdownMenuItem(
                        value: "teacher", child: Text("معلم")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      authController.selectedRole.value = value;
                    }
                  },
                )),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            authController.login();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                  ),
                  child: authController.isLoading.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          "تسجيل الدخول",
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                )),
            const SizedBox(height: 16),
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.createAccount);
                  },
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: "ليس لديك حساب؟ "),
                        TextSpan(
                          text: "إنشاء حساب",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _HoverableText({required this.text, required this.onTap});

  @override
  State<_HoverableText> createState() => _HoverableTextState();
}

class _HoverableTextState extends State<_HoverableText> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isHovered ? color.withValues(alpha: 0.7) : color,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(widget.text, style: style),
      ),
    );
  }
}

class _HoverableRichText extends StatefulWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const _HoverableRichText({
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  State<_HoverableRichText> createState() => _HoverableRichTextState();
}

class _HoverableRichTextState extends State<_HoverableRichText> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final baseStyle = Theme.of(context).textTheme.bodySmall;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text.rich(
          TextSpan(
            text: widget.prefix,
            style: baseStyle,
            children: [
              TextSpan(
                text: widget.action,
                style: baseStyle?.copyWith(
                  color: isHovered ? color.withValues(alpha: 0.7) : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
