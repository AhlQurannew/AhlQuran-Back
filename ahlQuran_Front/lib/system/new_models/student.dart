import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/account_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/contact_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/formal_education_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/guardian.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/medical_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/personal_info.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student_relations.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/lecture.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/subscription_info.dart';

class Student implements Model {
  PersonalInfo personalInfo = PersonalInfo();
  AccountInfo accountInfo = AccountInfo();
  ContactInfo contactInfo = ContactInfo();
  MedicalInfo medicalInfo = MedicalInfo();
  Guardian guardian = Guardian();
  List<Lecture> lectures = [];
  StudentRelations student = StudentRelations();
  FormalEducationInfo formalEducationInfo = FormalEducationInfo();
  SubscriptionInfo subscriptionInfo = SubscriptionInfo();

  // Constructor for empty form initialization
  Student();

  // Getter for student ID
  int? get id => personalInfo.studentId is int
      ? personalInfo.studentId
      : (personalInfo.studentId != null
          ? int.tryParse(personalInfo.studentId.toString())
          : null);

  @override
  // Method to check if all required fields are filled
  bool get isComplete {
    return (personalInfo.firstNameAr != null &&
            personalInfo.firstNameAr!.isNotEmpty) &&
        (personalInfo.lastNameAr != null &&
            personalInfo.lastNameAr!.isNotEmpty) &&
        (personalInfo.sex != null && personalInfo.sex!.isNotEmpty) &&
        (accountInfo.username != null && accountInfo.username!.isNotEmpty) &&
        (accountInfo.passcode != null && accountInfo.passcode!.isNotEmpty) &&
        (contactInfo.phoneNumber != null &&
            contactInfo.phoneNumber!.isNotEmpty) &&
        (contactInfo.email != null && contactInfo.email.isNotEmpty);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'personalInfo': personalInfo.toJson(),
      'accountInfo': accountInfo.toJson(),
      'contactInfo': contactInfo.toJson(),
      'medicalInfo': medicalInfo.toJson(),
      'guardian': guardian.toJson(),
      'student': student.toJson(),
      'lectures': lectures.map((lecture) => lecture.toJson()).toList(),
      'formalEducationInfo': formalEducationInfo.toJson(),
      'subscriptionInfo': subscriptionInfo.toJson(),
    };
  }

  static Student fromJson(Map<String, dynamic> json) {
    final student = Student();

    // First, extract the top-level ID and store it
    final topLevelId = json['id'];

    student.personalInfo = json['personalInfo'] != null
        ? PersonalInfo.fromJson(json['personalInfo'])
        : PersonalInfo();

    student.accountInfo = json['accountInfo'] != null
        ? AccountInfo.fromJson(json['accountInfo'])
        : AccountInfo();

    student.contactInfo = json['contactInfo'] != null
        ? ContactInfo.fromJson(json['contactInfo'])
        : ContactInfo();

    student.medicalInfo = json['medicalInfo'] != null
        ? MedicalInfo.fromJson(json['medicalInfo'])
        : MedicalInfo();

    student.guardian = json['guardian'] != null
        ? Guardian.fromJson(json['guardian'])
        : Guardian();

    student.student = json['student'] != null
        ? StudentRelations.fromJson(json['student'])
        : StudentRelations();

    student.lectures = json['lectures'] != null
        ? (json['lectures'] as List)
            .map((lecture) => Lecture.fromJson(lecture))
            .toList()
        : [];

    student.formalEducationInfo = json['formalEducationInfo'] != null
        ? FormalEducationInfo.fromJson(json['formalEducationInfo'])
        : FormalEducationInfo();

    student.subscriptionInfo = json['subscriptionInfo'] != null
        ? SubscriptionInfo.fromJson(json['subscriptionInfo'])
        : SubscriptionInfo();

    // Map top-level ID to personalInfo.studentId
    // This ensures the ID is available even if personalInfo doesn't have it
    if (topLevelId != null) {
      student.personalInfo.studentId = topLevelId;
    }

    return student;
  }
}
