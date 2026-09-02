import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Acheivement implements Model {
  int studentID;
  String studentName;
  Acheivement({required this.studentID, required this.studentName});
  String getStudentName() => studentName;
  int getId() => studentID;
  factory Acheivement.fromJson(Map<String, dynamic> json) => Acheivement(
        studentID: json['student_id'],
        studentName: json['full_name'],
      );

  @override
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentID,
      'full_name': studentName,
    };
  }

  @override
  bool get isComplete => studentID != 0 && studentName.isNotEmpty;
}
