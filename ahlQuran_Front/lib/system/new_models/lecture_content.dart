import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class LectureContent implements Model {
  dynamic id;
  dynamic fromSurah;
  dynamic fromAyah;
  dynamic toSurah;
  dynamic toAyah;
  dynamic observation;
  dynamic studentId;
  dynamic lectureId;
  dynamic type;

  LectureContent({
    this.id,
    this.fromSurah,
    this.fromAyah,
    this.toSurah,
    this.toAyah,
    this.observation,
    this.studentId,
    this.lectureId,
    this.type,
  });

  factory LectureContent.fromJson(Map<String, dynamic> json) => LectureContent(
        id: json['id'],
        fromSurah: json['from_surah'],
        fromAyah: json['from_ayah'],
        toSurah: json['to_surah'],
        toAyah: json['to_ayah'],
        observation: json['observation'],
        studentId: json['student_id'],
        lectureId: json['lecture_id'],
        type: json['type'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'from_surah': fromSurah,
        'from_ayah': fromAyah,
        'to_surah': toSurah,
        'to_ayah': toAyah,
        'observation': observation,
        'student_id': studentId,
        'lecture_id': lectureId,
        'type': type,
      };

  @override
  bool get isComplete {
    return fromSurah != null &&
        fromAyah != null &&
        toSurah != null &&
        toAyah != null &&
        studentId != null &&
        lectureId != null &&
        type != null;
  }
}
