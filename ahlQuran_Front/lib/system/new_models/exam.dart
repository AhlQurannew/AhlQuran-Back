import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Exam implements Model {
  dynamic examId;
  dynamic examLevelId;
  dynamic examNameAr;
  dynamic examNameEn;
  dynamic examType;
  dynamic examSucessMinPoint;
  dynamic examMaxPoint;
  dynamic examMemoPoint;
  dynamic examTjwidAppPoint;
  dynamic examTjwidThoPoint;
  dynamic examPerformancePoint;

  Exam({
    this.examId,
    this.examLevelId,
    this.examNameAr,
    this.examNameEn,
    this.examType,
    this.examSucessMinPoint,
    this.examMaxPoint,
    this.examMemoPoint,
    this.examTjwidAppPoint,
    this.examTjwidThoPoint,
    this.examPerformancePoint,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        examId: json['exam_id'],
        examLevelId: json['exam_level_id'],
        examNameAr: json['exam_name_ar'],
        examNameEn: json['exam_name_en'],
        examType: json['exam_type'],
        examSucessMinPoint: json['exam_sucess_min_point'],
        examMaxPoint: json['exam_max_point'],
        examMemoPoint: json['exam_memo_point'],
        examTjwidAppPoint: json['exam_tjwid_app_point'],
        examTjwidThoPoint: json['exam_tjwid_tho_point'],
        examPerformancePoint: json['exam_performance_point'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'exam_level_id': examLevelId,
        'exam_name_ar': examNameAr,
        'exam_name_en': examNameEn,
        'exam_type': examType,
        'exam_sucess_min_point': examSucessMinPoint,
        'exam_max_point': examMaxPoint,
        'exam_memo_point': examMemoPoint,
        'exam_tjwid_app_point': examTjwidAppPoint,
        'exam_tjwid_tho_point': examTjwidThoPoint,
        'exam_performance_point': examPerformancePoint,
      };

  @override
  bool get isComplete =>
      examNameAr != null &&
      examNameEn != null &&
      examType != null &&
      examSucessMinPoint != null &&
      examMaxPoint != null &&
      examMemoPoint != null &&
      examTjwidAppPoint != null &&
      examTjwidThoPoint != null &&
      examPerformancePoint != null;

  @override
  String toString() {
    return '$examNameEn - $examNameAr';
  }
}
