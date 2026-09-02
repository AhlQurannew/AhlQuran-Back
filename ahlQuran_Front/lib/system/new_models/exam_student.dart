import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class ExamStudent implements Model {
  dynamic examId;
  dynamic studentId;
  dynamic appreciationId;
  dynamic pointHifd;
  dynamic pointTajwidApplicative;
  dynamic pointTajwidTheoric;
  dynamic pointPerformance;
  dynamic pointDeductionTal;
  dynamic pointDeductionTanbihi;
  dynamic pointDeductionTajwidi;
  dynamic dateTakeExam;

  ExamStudent({
    this.examId,
    this.studentId,
    this.appreciationId,
    this.pointHifd,
    this.pointTajwidApplicative,
    this.pointTajwidTheoric,
    this.pointPerformance,
    this.pointDeductionTal,
    this.pointDeductionTanbihi,
    this.pointDeductionTajwidi,
    this.dateTakeExam,
  });

  factory ExamStudent.fromJson(Map<String, dynamic> json) => ExamStudent(
        examId: json['exam_id'],
        studentId: json['student_id'],
        appreciationId: json['appreciation_id'],
        pointHifd: json['point_hifd'],
        pointTajwidApplicative: json['point_tajwid_applicative'],
        pointTajwidTheoric: json['point_tajwid_theoric'],
        pointPerformance: json['point_performance'],
        pointDeductionTal: json['point_deduction_tal'],
        pointDeductionTanbihi: json['point_deduction_tanbihi'],
        pointDeductionTajwidi: json['point_deduction_tajwidi'],
        dateTakeExam: json['date_take_exam'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'student_id': studentId,
        'appreciation_id': appreciationId,
        'point_hifd': pointHifd,
        'point_tajwid_applicative': pointTajwidApplicative,
        'point_tajwid_theoric': pointTajwidTheoric,
        'point_performance': pointPerformance,
        'point_deduction_tal': pointDeductionTal,
        'point_deduction_tanbihi': pointDeductionTanbihi,
        'point_deduction_tajwidi': pointDeductionTajwidi,
        'date_take_exam': dateTakeExam,
      };

  @override
  bool get isComplete =>
      examId != null &&
      studentId != null &&
      appreciationId != null &&
      pointHifd != null &&
      pointTajwidApplicative != null &&
      pointTajwidTheoric != null &&
      pointPerformance != null &&
      pointDeductionTal != null &&
      pointDeductionTanbihi != null &&
      pointDeductionTajwidi != null &&
      dateTakeExam != null;
}
