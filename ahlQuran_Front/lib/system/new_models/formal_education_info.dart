import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class FormalEducationInfo implements Model {
  dynamic studentId;
  dynamic schoolName;
  dynamic schoolType;
  dynamic grade;
  dynamic academicLevel;

  FormalEducationInfo({
    this.studentId,
    this.schoolName,
    this.schoolType,
    this.grade,
    this.academicLevel,
  });

  factory FormalEducationInfo.fromJson(Map<String, dynamic> json) =>
      FormalEducationInfo(
        studentId: json['studentId'] ?? json['student_id'],
        schoolName: json['schoolName'] ?? json['school_name'],
        schoolType: json['schoolType'] ?? json['school_type'],
        grade: json['grade'],
        academicLevel: json['academicLevel'] ?? json['academic_level'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'school_name': schoolName,
        'grade': grade,
        'academic_level': academicLevel,
      };

  @override
  bool get isComplete =>
      studentId != null &&
      schoolName != null &&
      schoolType != null &&
      grade != null &&
      academicLevel != null;
}
