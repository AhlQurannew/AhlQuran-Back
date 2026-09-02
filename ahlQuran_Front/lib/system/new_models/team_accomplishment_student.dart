import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class TeamAccomplishmentStudent implements Model {
  dynamic teamAccomplishmentId;
  dynamic studentId;

  TeamAccomplishmentStudent({
    this.teamAccomplishmentId,
    this.studentId,
  });

  factory TeamAccomplishmentStudent.fromJson(Map<String, dynamic> json) =>
      TeamAccomplishmentStudent(
        teamAccomplishmentId: json['team_accomplishment_id'],
        studentId: json['student_id'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'team_accomplishment_id': teamAccomplishmentId,
        'student_id': studentId,
      };

  @override
  bool get isComplete => teamAccomplishmentId != null && studentId != null;
}
