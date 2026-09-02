import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class WeeklySchedule implements Model {
  dynamic weeklyScheduleId;
  dynamic dayOfWeek;
  dynamic lectureId;
  dynamic startTime;
  dynamic endTime;
  WeeklySchedule({
    this.weeklyScheduleId,
    this.dayOfWeek,
    this.lectureId,
    this.startTime,
    this.endTime,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) => WeeklySchedule(
        weeklyScheduleId: json['weekly_schedule_id'],
        dayOfWeek: json['day_of_week'],
        lectureId: json['lecture_id'],
        startTime: json['start_time'],
        endTime: json['end_time'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'weekly_schedule_id': weeklyScheduleId,
        'day_of_week': dayOfWeek,
        'lecture_id': lectureId,
        'start_time': startTime,
        'end_time': endTime,
      };

  @override
  bool get isComplete =>
      weeklyScheduleId != null &&
      dayOfWeek != null &&
      lectureId != null &&
      startTime != null &&
      endTime != null;
}
