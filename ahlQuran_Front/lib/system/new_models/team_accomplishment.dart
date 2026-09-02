import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class TeamAccomplishment implements Model {
  dynamic teamAccomplishmentId;
  dynamic fromSurah;
  dynamic fromAyah;
  dynamic toSurah;
  dynamic toAyah;
  dynamic accompanyingCurriculumSubject;
  dynamic accompanyingCurriculumLesson;
  dynamic tajweedLesson;

  TeamAccomplishment({
    this.teamAccomplishmentId,
    this.fromSurah,
    this.fromAyah,
    this.toSurah,
    this.toAyah,
    this.accompanyingCurriculumSubject,
    this.accompanyingCurriculumLesson,
    this.tajweedLesson,
  });

  factory TeamAccomplishment.fromJson(Map<String, dynamic> json) =>
      TeamAccomplishment(
        teamAccomplishmentId: json['team_accomplishment_id'],
        fromSurah: json['from_surah'],
        fromAyah: json['from_ayah'],
        toSurah: json['to_surah'],
        toAyah: json['to_ayah'],
        accompanyingCurriculumSubject: json['accompanying_curriculum_subject'],
        accompanyingCurriculumLesson: json['accompanying_curriculum_lesson'],
        tajweedLesson: json['tajweed_lesson'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'team_accomplishment_id': teamAccomplishmentId,
        'from_surah': fromSurah,
        'from_ayah': fromAyah,
        'to_surah': toSurah,
        'to_ayah': toAyah,
        'accompanying_curriculum_subject': accompanyingCurriculumSubject,
        'accompanying_curriculum_lesson': accompanyingCurriculumLesson,
        'tajweed_lesson': tajweedLesson,
      };

  @override
  bool get isComplete =>
      teamAccomplishmentId != null &&
      fromSurah != null &&
      fromAyah != null &&
      toSurah != null &&
      toAyah != null;
}
