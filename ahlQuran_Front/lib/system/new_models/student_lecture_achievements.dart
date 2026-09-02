import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class StudentLectureAchievements implements Model {
  dynamic lectureId;
  dynamic studentId;
  dynamic achievementType;
  dynamic lectureDate;
  dynamic fromSurah;
  dynamic fromAyah;
  dynamic toSurah;
  dynamic toAyah;
  dynamic teacherNote;

  StudentLectureAchievements({
    this.lectureId,
    this.studentId,
    this.achievementType,
    this.lectureDate,
    this.fromSurah,
    this.fromAyah,
    this.toSurah,
    this.toAyah,
    this.teacherNote,
  });

  factory StudentLectureAchievements.fromJson(Map<String, dynamic> json) =>
      StudentLectureAchievements(
        lectureId: json['lecture_id'],
        studentId: json['student_id'],
        achievementType: json['achievement_type'],
        lectureDate: json['lecture_date'],
        fromSurah: json['from_surah'],
        fromAyah: json['from_ayah'],
        toSurah: json['to_surah'],
        toAyah: json['to_ayah'],
        teacherNote: json['teacher_note'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'lecture_id': lectureId,
        'student_id': studentId,
        'achievement_type': achievementType,
        'lecture_date': lectureDate,
        'from_surah': fromSurah,
        'from_ayah': fromAyah,
        'to_surah': toSurah,
        'to_ayah': toAyah,
        'teacher_note': teacherNote,
      };

  @override
  bool get isComplete {
    return lectureId != null &&
        studentId != null &&
        achievementType != null &&
        lectureDate != null &&
        fromSurah != null &&
        fromAyah != null &&
        toSurah != null &&
        toAyah != null;
  }
}
