import 'package:flutter/material.dart';

//import '/widgets/custom_text_form_feild.dart';
class InputField extends StatelessWidget {
  final String inputTitle;
  final Widget child;

  const InputField({
    required this.inputTitle,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Match the teal color from CustomContainer
    final labelColor = const Color(0xFF2A9D8F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inputTitle,
          style: textTheme.titleSmall?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        child
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLines;
  final TextDirection textDirection;
  final bool readOnly;
  final void Function()? onTap;
  final Widget? suffixIcon; // NEW

  const CustomTextField({
    super.key,
    required this.controller,
    required this.onSaved,
    this.validator,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.textDirection = TextDirection.rtl,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      focusNode: focusNode,
      onChanged: onChanged,
      onSaved: (value) {
        debugPrint('onSaved called with value: $value');
        if (onSaved != null) {
          onSaved!(value);
        }
      },
      keyboardType: keyboardType,
      textDirection: textDirection,
      obscureText: obscureText,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
        hoverColor: Theme.of(context).inputDecorationTheme.hoverColor,
        suffixIcon: suffixIcon, // NEW
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }
}
