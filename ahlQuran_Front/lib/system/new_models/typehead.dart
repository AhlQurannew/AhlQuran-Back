class Typehead {
  final int sessionId;
  final String sessionNameAr;
  Typehead({required this.sessionId, required this.sessionNameAr});

  factory Typehead.fromJson(Map<String, dynamic> json) {
    return Typehead(
      sessionId: json['lecture_id'],
      sessionNameAr: json['lecture_name_ar'],
    );
  }
}
