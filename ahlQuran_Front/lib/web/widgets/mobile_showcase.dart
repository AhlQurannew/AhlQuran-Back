import 'package:flutter/material.dart';
import 'section_header.dart';

class MobileShowcase extends StatelessWidget {
  MobileShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            header: 'صور من التطبيق',
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/phone.png',
              width: 680,
            ),
          ),
        ],
      ),
    );
  }
}
