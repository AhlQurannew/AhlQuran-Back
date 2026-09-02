import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/account_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/contact_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/guardian.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/personal_info.dart';

class GuardianInfoDialog implements Model {
  //info
  Guardian guardian = Guardian();
  AccountInfo accountInfo = AccountInfo();
  ContactInfo contactInfo = ContactInfo();
  List<PersonalInfo> children = [];
  int? studentId; // Student under guardian's care

  GuardianInfoDialog();
  @override
  bool get isComplete {
    return guardian.firstName.isNotEmpty &&
        guardian.lastName.isNotEmpty &&
        guardian.relationship.isNotEmpty &&
        accountInfo.username.isNotEmpty &&
        accountInfo.passcode.isNotEmpty;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'info': guardian.toJson(),
      'contact_info': contactInfo.toJson(),
      'account_info': accountInfo.toJson(),
      'children': children.map((child) => child.toJson()).toList(),
      'student_id': studentId,
    };
  }

  GuardianInfoDialog.fromJson(Map<String, dynamic> map) {
    guardian = Guardian.fromJson(map['info']);
    contactInfo = ContactInfo.fromJson(map['contact_info']);
    accountInfo = AccountInfo.fromJson(map['account_info']);
    if (map['children'] != null) {
      children = List<PersonalInfo>.from(
          map['children'].map((child) => PersonalInfo.fromJson(child)));
    } else {
      children = [];
    }
    studentId = map['student_id'];
  }
}
