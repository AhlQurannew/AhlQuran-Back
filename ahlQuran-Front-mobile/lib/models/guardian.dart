class Guardian {
  final int id;
  final String firstName;
  final String lastName;
  final String? relationship;

  Guardian({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.relationship,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['guardian_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      relationship: json['relationship'],
    );
  }
}

class User {
  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final String message;
  final User user;
  final Guardian? guardian;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.message,
    required this.user,
    this.guardian,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      message: json['message'],
      user: User.fromJson(json['user']),
      guardian: json['guardian'] != null
          ? Guardian.fromJson(json['guardian'])
          : null,
    );
  }
}
