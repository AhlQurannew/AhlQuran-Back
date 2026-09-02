class PersonalInfo {
  final String? firstNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? lastNameEn;
  final String? sex;
  final String? dateOfBirth;
  final String? placeOfBirth;
  final String? homeAddress;
  final String? nationality;

  PersonalInfo({
    this.firstNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.lastNameEn,
    this.sex,
    this.dateOfBirth,
    this.placeOfBirth,
    this.homeAddress,
    this.nationality,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstNameAr: json['firstNameAr'],
      lastNameAr: json['lastNameAr'],
      firstNameEn: json['firstNameEn'],
      lastNameEn: json['lastNameEn'],
      sex: json['sex'],
      dateOfBirth: json['dateOfBirth'],
      placeOfBirth: json['placeOfBirth'],
      homeAddress: json['homeAddress'],
      nationality: json['nationality'],
    );
  }
}

class ContactInfo {
  final String? phoneNumber;
  final String? email;

  ContactInfo({this.phoneNumber, this.email});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(phoneNumber: json['phoneNumber'], email: json['email']);
  }
}

class Student {
  final int id;
  final int userId;
  final PersonalInfo personalInfo;
  final ContactInfo contactInfo;

  Student({
    required this.id,
    required this.userId,
    required this.personalInfo,
    required this.contactInfo,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] ?? {}),
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
    );
  }

  String get displayName {
    if (personalInfo.firstNameEn != null && personalInfo.lastNameEn != null) {
      return '${personalInfo.firstNameEn} ${personalInfo.lastNameEn}';
    }
    if (personalInfo.firstNameAr != null && personalInfo.lastNameAr != null) {
      return '${personalInfo.firstNameAr} ${personalInfo.lastNameAr}';
    }
    return 'Student #$id';
  }
}

class StudentListResponse {
  final List<Student> students;
  final int total;

  StudentListResponse({required this.students, required this.total});

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      students: (json['students'] as List)
          .map((student) => Student.fromJson(student))
          .toList(),
      total: json['total'],
    );
  }
}
