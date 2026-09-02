import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class MedicalInfo implements Model {
  dynamic studentId;
  dynamic bloodType;
  dynamic allergies;
  dynamic diseases;
  dynamic diseasesCauses;

  MedicalInfo({
    this.studentId,
    this.bloodType,
    this.allergies,
    this.diseases,
    this.diseasesCauses,
  });

  factory MedicalInfo.fromJson(Map<String, dynamic> json) => MedicalInfo(
        studentId: json['student_id'],
        bloodType: json['blood_type'],
        allergies: json['allergies'],
        diseases: json['diseases'],
        diseasesCauses: json['diseases_causes'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'blood_type': bloodType,
        'allergies': allergies,
        'diseases': diseases,
        'diseases_causes': diseasesCauses,
      };

  @override
  bool get isComplete =>
      studentId != null &&
      bloodType != null &&
      allergies != null &&
      diseases != null &&
      diseasesCauses != null;
}
