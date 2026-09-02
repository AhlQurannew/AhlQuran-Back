class SupervisorForm {
  final int? id;
  final String firstname;
  final String lastname;
  final String email;
  final String? password;

  SupervisorForm({
    this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
    };

    if (password != null && password!.isNotEmpty) {
      json['password'] = password!;
    }

    return json;
  }

  bool get isValid =>
      firstname.isNotEmpty &&
      lastname.isNotEmpty &&
      email.isNotEmpty &&
      (id != null || (password != null && password!.length >= 6));
}
