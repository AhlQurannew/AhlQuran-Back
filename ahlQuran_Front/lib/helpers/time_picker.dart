import 'package:flutter/material.dart';

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  TimeOfDay tempTime = initialTime;

  return await showDialog<TimeOfDay>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: tempTime.hour,
                        items: List.generate(24, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(index.toString().padLeft(2, '0')),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              tempTime =
                                  TimeOfDay(hour: val, minute: tempTime.minute);
                            });
                          }
                        },
                      ),
                      const Text(" : "),
                      DropdownButton<int>(
                        value: tempTime.minute,
                        items: List.generate(60, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(index.toString().padLeft(2, '0')),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              tempTime =
                                  TimeOfDay(hour: tempTime.hour, minute: val);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          final now = TimeOfDay.now();
                          Navigator.of(context).pop(now);
                        },
                        icon: Icon(Icons.access_time,
                            color: Theme.of(context).colorScheme.primary),
                        label: Text('الآن',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Text('إغلاق'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(tempTime);
                            },
                            child: const Text('تطبيق'),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
