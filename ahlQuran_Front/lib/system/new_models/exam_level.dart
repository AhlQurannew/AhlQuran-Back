import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class ExamLevel implements Model {
  dynamic examLevelId;
  dynamic level;
  dynamic fromSurah;
  dynamic fromAyah;
  dynamic toSurah;
  dynamic toAyah;

  ExamLevel({
    this.examLevelId,
    this.level,
    this.fromSurah,
    this.fromAyah,
    this.toSurah,
    this.toAyah,
  });

  factory ExamLevel.fromJson(Map<String, dynamic> json) => ExamLevel(
        examLevelId: json['exam_level_id'],
        level: json['level'],
        fromSurah: json['from_surah'],
        fromAyah: json['from_ayah'],
        toSurah: json['to_surah'],
        toAyah: json['to_ayah'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'exam_level_id': examLevelId,
        'level': level,
        'from_surah': fromSurah,
        'from_ayah': fromAyah,
        'to_surah': toSurah,
        'to_ayah': toAyah,
      };

  @override
  bool get isComplete =>
      examLevelId != null &&
      level != null &&
      fromSurah != null &&
      fromAyah != null &&
      toSurah != null &&
      toAyah != null;
}
