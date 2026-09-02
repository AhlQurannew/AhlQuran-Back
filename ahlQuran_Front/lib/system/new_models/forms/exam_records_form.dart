import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/appreciation.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/exam_student.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/personal_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student_relations.dart';

class ExamRecordInfoDialog implements Model {
  Exam exam = Exam();
  StudentRelations student = StudentRelations();
  PersonalInfo personalInfo = PersonalInfo();
  ExamStudent examStudent = ExamStudent();
  Appreciation appreciation = Appreciation();

  ExamRecordInfoDialog();
  @override
  bool get isComplete {
    return exam.examType.isNotEmpty &&
        examStudent.appreciationId != null &&
        examStudent.dateTakeExam.isNotEmpty &&
        personalInfo.firstNameAr.isNotEmpty &&
        personalInfo.lastNameAr.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'exam': exam.toJson(),
      'student': student.toJson(),
      'personal_info': personalInfo.toJson(),
      'exam_student': examStudent.toJson(),
      'appreciation': appreciation.toJson()
    };
  }

  ExamRecordInfoDialog.fromJson(Map<String, dynamic> map) {
    exam = Exam.fromJson(map['exam']);
    student = StudentRelations.fromJson(map['student']);
    personalInfo = PersonalInfo.fromJson(map['personal_info']);
    examStudent = ExamStudent.fromJson(map['exam_student']);
    appreciation = Appreciation.fromJson(map['appreciation']);
  }
}
