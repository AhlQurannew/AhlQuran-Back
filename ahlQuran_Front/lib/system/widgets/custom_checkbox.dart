import 'package:flutter/material.dart';

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    required String text,
    required String errorText,
    bool initialValue = false,
  }) : super(
          initialValue: initialValue,
          validator: (value) => value == true ? null : errorText,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Checkbox(
                        value: state.value ?? false,
                        onChanged: (value) {
                          state.didChange(value);
                        },
                      ),
                      const Text('اوافق على '),
                      Text(
                        text,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                if (state.hasError) // Show error if validation fails
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
