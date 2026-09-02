import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/account_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class TeacherInfoDialog implements Model {
  int? teacherId;
  int? userId;
  String firstName = '';
  String lastName = '';
  String email = '';
  String riwaya = '';
  String? hireDate;
  bool isActive = true;

  // Account info for creation
  AccountInfo accountInfo = AccountInfo();

  TeacherInfoDialog();

  @override
  bool get isComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        riwaya.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': teacherId,
      'user_id': userId,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'riwaya': riwaya,
      'hire_date': hireDate,
      'is_active': isActive,
    };
  }

  TeacherInfoDialog.fromJson(Map<String, dynamic> map) {
    teacherId = map['id'];
    userId = map['user_id'];
    firstName = map['firstname'] ?? '';
    lastName = map['lastname'] ?? '';
    email = map['email'] ?? '';
    riwaya = map['riwaya'] ?? '';
    hireDate = map['hire_date'];
    isActive = map['is_active'] ?? true;
  }
}
