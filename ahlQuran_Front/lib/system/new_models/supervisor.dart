import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class Supervisor implements Model {
  final int? id;
  final int? userId;
  final String? firstname;
  final String? lastname;
  final String? email;
  final bool? isActive;
  final DateTime? createdAt;

  Supervisor({
    this.id,
    this.userId,
    this.firstname,
    this.lastname,
    this.email,
    this.isActive,
    this.createdAt,
  });

  factory Supervisor.fromJson(Map<String, dynamic> json) => Supervisor(
        id: json['id'],
        userId: json['user_id'],
        firstname: json['firstname'],
        lastname: json['lastname'],
        email: json['email'],
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  bool get isComplete =>
      id != null && firstname != null && lastname != null && email != null;

  String get fullName => '${firstname ?? ''} ${lastname ?? ''}'.trim();
}
