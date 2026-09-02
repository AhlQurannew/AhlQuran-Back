import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/lecture.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/weekly_schedule.dart';

class LectureForm implements Model {
  //lecture info
  //required
  late Lecture lecture = Lecture();
  late List<Teacher> teachers = [];
  //lecture schedule
  late List<WeeklySchedule> schedules;
  int studentCount;

  LectureForm(
      {Lecture? lecture,
      List<Teacher>? teachers,
      List<WeeklySchedule>? schedules,
      this.studentCount = 0})
      : lecture = lecture ?? Lecture(),
        teachers = teachers ?? [],
        schedules = schedules ?? [];

  static var fromJson = (Map<String, dynamic> json) {
    // Handle both response formats:
    // 1. Nested format: {lecture: {...}, teachers: [...], schedules: [...]}
    // 2. Flat format: {lecture_id: 1, lecture_name_ar: ..., teachers: [...], schedules: [...]}

    Map<String, dynamic> lectureData;
    if (json.containsKey('lecture')) {
      // Nested format (from create/update responses)
      lectureData = json['lecture'] ?? {};
    } else {
      // Flat format (from GET responses) - extract lecture fields
      lectureData = {
        'lecture_id': json['lecture_id'],
        'lecture_name_ar': json['lecture_name_ar'],
        'lecture_name_en': json['lecture_name_en'],
        'circle_type': json['circle_type'],
        'category': json['category'],
        'shown_on_website': json['shown_on_website'],
      };
    }

    return LectureForm(studentCount: json['student_count'] ?? 0)
      ..lecture = Lecture.fromJson(lectureData)
      ..teachers = (json['teachers'] as List<dynamic>? ?? [])
          .map((t) => Teacher.fromJson(t))
          .toList()
      ..schedules = (json['schedules'] as List<dynamic>? ?? [])
          .map((s) => WeeklySchedule.fromJson(s))
          .toList();
  };

  @override
  bool get isComplete {
    return lecture.lectureNameAr.isNotEmpty &&
        lecture.lectureNameEn.isNotEmpty &&
        lecture.circleType.isNotEmpty &&
        schedules.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "lecture": {
        "lecture_id": lecture.lectureId,
        "lecture_name_ar": lecture.lectureNameAr,
        "lecture_name_en": lecture.lectureNameEn,
        "circle_type": lecture.circleType,
        "category": lecture.category,
        "shown_on_website": lecture.shownOnWebsite
      },
      "teachers": teachers.map((t) => {"teacher_id": t.teacherId}).toList(),
      "schedules": schedules.map((s) => s.toJson()).toList(),
      "student_count": studentCount,
    };
  }
}
