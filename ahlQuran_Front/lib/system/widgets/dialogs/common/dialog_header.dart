import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog header widget with title + close button
class DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const DialogHeader({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2A9D8F), // Teal color to match design
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              debugPrint('DialogHeader close button pressed');
              if (onClose != null) {
                debugPrint('Calling onClose callback');
                onClose!();
              } else {
                debugPrint('No onClose callback, calling Get.back()');
                Get.back();
              }
            },
          )
        ],
      ),
    );
  }
}
