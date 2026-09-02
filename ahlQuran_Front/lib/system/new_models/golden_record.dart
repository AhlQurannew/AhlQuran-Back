import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class GoldenRecord implements Model {
  dynamic goldenRecordId;
  dynamic studentId;
  dynamic recordType;
  dynamic riwayah;
  dynamic dateOfCompletion;
  dynamic schoolName;

  GoldenRecord({
    this.goldenRecordId,
    this.studentId,
    this.recordType,
    this.riwayah,
    this.dateOfCompletion,
    this.schoolName,
  });

  factory GoldenRecord.fromJson(Map<String, dynamic> json) => GoldenRecord(
        goldenRecordId: json['golden_record_id'],
        studentId: json['student_id'],
        recordType: json['record_type'],
        riwayah: json['riwayah'],
        dateOfCompletion: json['date_of_completion'],
        schoolName: json['school_name'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'golden_record_id': goldenRecordId,
        'student_id': studentId,
        'record_type': recordType,
        'riwayah': riwayah,
        'date_of_completion': dateOfCompletion,
        'school_name': schoolName,
      };

  @override
  bool get isComplete =>
      goldenRecordId != null &&
      studentId != null &&
      recordType != null &&
      riwayah != null &&
      dateOfCompletion != null &&
      schoolName != null;
}
