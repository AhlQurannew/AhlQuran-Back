import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Guardian implements Model {
  dynamic id;
  dynamic lastName;
  dynamic firstName;
  dynamic dateOfBirth;
  dynamic relationship;
  dynamic phoneNumber;
  dynamic homeAddress;
  dynamic email;
  dynamic job;
  String? guardianAccount;
  List<String>? children;

  @override
  Map<String, dynamic> toJson() {
    return {
      'guardian_id': id,
      'lastName': lastName,
      'first_name': firstName,
      'date_of_birth': dateOfBirth,
      'relationship': relationship,
      'phone_number': phoneNumber,
      'home_address': homeAddress,
      'email': email,
      'job': job,
      'guardian_account': guardianAccount,
      'children': children?.join(',') ?? '',
    };
  }

  Guardian({
    this.id,
    this.lastName,
    this.firstName,
    this.dateOfBirth,
    this.relationship,
    this.phoneNumber,
    this.homeAddress,
    this.email,
    this.job,
    this.guardianAccount,
    this.children,
  });

  factory Guardian.fromJson(Map<String, dynamic> map) {
    // Handle children: empty string → empty list or null
    List<String>? parsedChildren;
    final rawChildren = map['children'];
    if (rawChildren != null &&
        rawChildren is String &&
        rawChildren.trim().isNotEmpty) {
      parsedChildren = rawChildren.split(',').map((e) => e.trim()).toList();
    }

    return Guardian(
      id: map['id'].toString(),
      lastName: map['lastName'] ?? '',
      firstName: map['firstName'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      homeAddress: map['home_address'] ?? '',
      email: map['email'] ?? '',
      job: map['job'] ?? '',
      guardianAccount: map['guardianAccount'],
      children: parsedChildren,
    );
  }

  @override
  bool get isComplete =>
      lastName != null &&
      lastName.toString().trim().isNotEmpty &&
      firstName != null &&
      firstName.toString().trim().isNotEmpty &&
      dateOfBirth != null &&
      dateOfBirth.toString().trim().isNotEmpty &&
      relationship != null &&
      relationship.toString().trim().isNotEmpty &&
      phoneNumber != null &&
      phoneNumber.toString().trim().isNotEmpty &&
      homeAddress != null &&
      homeAddress.toString().trim().isNotEmpty &&
      email != null &&
      email.toString().trim().isNotEmpty &&
      job != null &&
      job.toString().trim().isNotEmpty;
}
