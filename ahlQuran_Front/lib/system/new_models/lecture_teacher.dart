import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class LectureTeacher implements Model {
  dynamic teacherId;
  dynamic lectureId;
  dynamic lectureDate;
  dynamic attendanceStatus;

  LectureTeacher({
    this.teacherId,
    this.lectureId,
    this.lectureDate,
    this.attendanceStatus,
  });

  factory LectureTeacher.fromJson(Map<String, dynamic> json) => LectureTeacher(
        teacherId: json['teacher_id'],
        lectureId: json['lecture_id'],
        lectureDate: json['lecture_date'],
        attendanceStatus: json['attendance_status'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'teacher_id': teacherId,
        'lecture_id': lectureId,
        'lecture_date': lectureDate,
        'attendance_status': attendanceStatus,
      };

  @override
  // TODO: implement isComplete
  bool get isComplete =>
      teacherId != null &&
      lectureId != null &&
      lectureDate != null &&
      attendanceStatus != null;
}
