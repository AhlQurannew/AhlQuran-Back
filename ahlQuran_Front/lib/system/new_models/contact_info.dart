import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class ContactInfo implements Model {
  dynamic contactId;
  dynamic email;
  dynamic phoneNumber;

  ContactInfo({
    this.contactId,
    this.email,
    this.phoneNumber,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        contactId: json['contactId'] ?? json['contact_id'],
        email: json['email'],
        phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'contact_id': contactId,
        'email': email,
        'phone_number': phoneNumber,
      };

  @override
  bool get isComplete =>
      contactId != null && email != null && phoneNumber != null;
}
