import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Copy implements Model {
  String? schoolName;
  String? country;
  String? schoolAddress;
  String? name;
  String? supervisorName;
  String? phoneNumber;
  String? email;

  Copy();

  @override
  bool get isComplete {
    return schoolName != null &&
        country != null &&
        schoolAddress != null &&
        name != null &&
        supervisorName != null &&
        phoneNumber != null &&
        email != null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "schoolName": schoolName,
      "country": country,
      "schoolAddress": schoolAddress,
      "name": name,
      "nameOfSupervisor": supervisorName,
      "phoneNumber": phoneNumber,
      "email": email,
    };
  }
}
