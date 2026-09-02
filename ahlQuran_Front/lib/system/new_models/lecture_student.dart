import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class LectureStudent implements Model {
  dynamic lectureId;
  dynamic studentId;
  dynamic attendanceStatus;
  dynamic lectureDate;

  LectureStudent({
    this.lectureId,
    this.studentId,
    this.attendanceStatus,
    this.lectureDate,
  });

  factory LectureStudent.fromJson(Map<String, dynamic> json) => LectureStudent(
        lectureId: json['lecture_id'],
        studentId: json['student_id'],
        attendanceStatus: json['attendance_status'],
        lectureDate: json['lecture_date'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'lecture_id': lectureId,
        'student_id': studentId,
        'attendance_status': attendanceStatus,
        'lecture_date': lectureDate,
      };

  @override
  bool get isComplete =>
      lectureId != null &&
      studentId != null &&
      attendanceStatus != null &&
      lectureDate != null;
}
