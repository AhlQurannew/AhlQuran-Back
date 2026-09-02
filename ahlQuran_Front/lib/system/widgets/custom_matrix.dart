import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/weekly_schedule.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/time_picker.dart';
import '../utils/snackbar_helper.dart';

class TimeCellController extends GetxController {
  final Map<String, RxBool> weekDays = {
    'الجمعة': false.obs,
    'السبت': false.obs,
    'الأحد': false.obs,
    'الإثنين': false.obs,
    'الثلاثاء': false.obs,
    'الأربعاء': false.obs,
    'الخميس': false.obs,
  };

  final Map<String, Map<String, RxString>> dayTimes = {
    'الجمعة': {'from': ''.obs, 'to': ''.obs},
    'السبت': {'from': ''.obs, 'to': ''.obs},
    'الأحد': {'from': ''.obs, 'to': ''.obs},
    'الإثنين': {'from': ''.obs, 'to': ''.obs},
    'الثلاثاء': {'from': ''.obs, 'to': ''.obs},
    'الأربعاء': {'from': ''.obs, 'to': ''.obs},
    'الخميس': {'from': ''.obs, 'to': ''.obs},
  };

  void toggleSwitch(String day) => weekDays[day]!.toggle();

  void clearTime(String day, String type) => dayTimes[day]![type]!.value = '';

  void setTime(String day, String type, String newTime) {
    if (!_isValidTime(newTime)) {
      showErrorSnackbar('يرجى إدخال الوقت بصيغة HH:MM');
      return;
    }

    final otherType = type == 'from' ? 'to' : 'from';
    final otherTime = dayTimes[day]![otherType]!.value;

    if (otherTime.isNotEmpty) {
      if (type == 'from' && !_isFromBeforeTo(newTime, otherTime)) {
        showErrorSnackbar('وقت البداية يجب أن يكون قبل وقت النهاية');
        return;
      }
      if (type == 'to' &&
          !_isFromBeforeTo(dayTimes[day]!['from']!.value, newTime)) {
        showErrorSnackbar('وقت النهاية يجب أن يكون بعد وقت البداية');
        return;
      }
    }

    dayTimes[day]![type]!.value = newTime;
  }

  bool _isValidTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    return hours != null &&
        minutes != null &&
        hours >= 0 &&
        hours <= 23 &&
        minutes >= 0 &&
        minutes <= 59;
  }

  bool _isFromBeforeTo(String from, String to) {
    final fromMinutes = _timeToMinutes(from);
    final toMinutes = _timeToMinutes(to);
    return fromMinutes < toMinutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  List<WeeklySchedule> getSelectedDays() {
    final List<WeeklySchedule> result = [];

    for (var entry in weekDays.entries) {
      if (entry.value.value) {
        final day = entry.key;
        final fromTime = dayTimes[day]!['from']!.value;
        final toTime = dayTimes[day]!['to']!.value;

        if (fromTime.isEmpty || toTime.isEmpty) {
          showErrorSnackbar('يرجى تحديد وقت البداية والنهاية ليوم $day');
          continue;
        }

        result.add(WeeklySchedule(
          weeklyScheduleId: 0,
          dayOfWeek: day,
          startTime: fromTime,
          endTime: toTime,
          lectureId: 0,
        ));
      }
    }

    return result;
  }

  /// Load existing schedules into the matrix (for editing)
  void loadSchedules(List<WeeklySchedule> schedules) {
    // First, clear all selections
    clearAll();

    // Then, populate with existing data
    for (var schedule in schedules) {
      final day = schedule.dayOfWeek as String;
      if (weekDays.containsKey(day)) {
        weekDays[day]!.value = true;
        dayTimes[day]!['from']!.value = schedule.startTime ?? '';
        dayTimes[day]!['to']!.value = schedule.endTime ?? '';
      }
    }
  }

  /// Clear all selections and times
  void clearAll() {
    for (var day in weekDays.keys) {
      weekDays[day]!.value = false;
      dayTimes[day]!['from']!.value = '';
      dayTimes[day]!['to']!.value = '';
    }
  }
}

class CustomMatrix extends StatelessWidget {
  final TimeCellController controller;

  const CustomMatrix({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: <TableRow>[
        TableRow(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.primary),
          children: [
            _buildHeaderCell(context, 'اليوم'),
            _buildHeaderCell(context, 'الحالة'),
            _buildHeaderCell(context, 'من'),
            _buildHeaderCell(context, 'إلى'),
          ],
        ),
        ...controller.weekDays.entries.map((entry) {
          String day = entry.key;
          return TableRow(
            children: [
              _buildDataCell(context, day),
              _buildSwitchCell(controller, day),
              TimeCell(controller: controller, day: day, isFrom: true),
              TimeCell(controller: controller, day: day, isFrom: false),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildSwitchCell(TimeCellController controller, String day) {
    return Obx(() => Center(
          child: Switch(
            value: controller.weekDays[day]!.value,
            onChanged: (value) {
              controller.toggleSwitch(day);
              if (!value) {
                controller.clearTime(day, 'from');
                controller.clearTime(day, 'to');
              }
            },
          ),
        ));
  }
}

class TimeCell extends StatelessWidget {
  final TimeCellController controller;
  final String day;
  final bool isFrom;

  const TimeCell({
    super.key,
    required this.controller,
    required this.day,
    required this.isFrom,
  });

  @override
  Widget build(BuildContext context) {
    final timeType = isFrom ? 'from' : 'to';

    return Obx(() {
      final isSelected = controller.weekDays[day]!.value;
      final timeValue = controller.dayTimes[day]![timeType]!.value;

      return TextButton(
        onPressed: () async {
          if (isSelected) {
            final picked = await showCustomTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              final formattedTime =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              controller.setTime(day, timeType, formattedTime);
            }
          }
        },
        child: Text(
          timeValue.isEmpty ? (isFrom ? 'ابدأ' : 'انتهِ') : timeValue,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: timeValue.isEmpty
                    ? Theme.of(context).hintColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
        ),
      );
    });
  }
}
