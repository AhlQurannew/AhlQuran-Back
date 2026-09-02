// lib/system/widgets/dialogs/utils/dialog_utils.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildDialogHeader(BuildContext context, {String? backgroundImage}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Stack(
    children: [
      if (backgroundImage != null)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ClipRRect(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
        )
      else
        Container(
          width: double.infinity,
          height: 50,
          color: colorScheme.primary,
        ),
      Row(
        children: [
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    ],
  );
}

Widget buildDialogContainer({
  required Widget child,
  required ScrollController scrollController,
  EdgeInsetsGeometry? padding,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: Get.width * 0.7,
      maxHeight: Get.height * 0.8,
      minHeight: 400,
      minWidth: 300,
    ),
    child: Dialog(
      shape: const BeveledRectangleBorder(),
      child: Scrollbar(
        controller: scrollController,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSubmitButton({
  required VoidCallback onPressed,
  required RxBool isLoading,
}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Obx(
      () => ElevatedButton(
        onPressed: isLoading.value ? null : onPressed,
        child: isLoading.value
            ? const CircularProgressIndicator()
            : const Text('Submit'),
      ),
    ),
  );
}
