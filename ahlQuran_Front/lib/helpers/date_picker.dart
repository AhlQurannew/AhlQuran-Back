import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime tempDate = initialDate;

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return await showDialog<DateTime>(
    context: context,
    builder: (context) {
      return Localizations.override(
        context: context,
        locale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDatePicker(
                      initialDate: tempDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      onDateChanged: (date) {
                        tempDate = date;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            tempDate = DateTime.now();
                            Navigator.of(context).pop(tempDate);
                          },
                          icon: Icon(Icons.today, color: colorScheme.primary),
                          label: Text(
                            'اليوم',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: Text(
                                'إغلاق',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(tempDate);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('تطبيق'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
