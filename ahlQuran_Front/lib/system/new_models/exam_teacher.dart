import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class ExamTeacher implements Model {
  dynamic examId;
  dynamic teacherId;
  dynamic date;

  ExamTeacher({
    this.examId,
    this.teacherId,
    this.date,
  });

  factory ExamTeacher.fromJson(Map<String, dynamic> json) => ExamTeacher(
        examId: json['exam_id'],
        teacherId: json['teacher_id'],
        date: json['date'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'teacher_id': teacherId,
        'date': date,
      };

  @override
  bool get isComplete => examId != null && teacherId != null && date != null;
}
