import '../../../data/quran_data.dart';

class Achievement {
  final int? id;
  final int studentId;
  final int fromSurah; // Changed to chapter number
  final int toSurah; // Changed to chapter number
  final int fromVerse;
  final int toVerse;
  final String? note;
  final String achievementType; // "normal", "small", "big"
  final String date; // Format: DD-MM-YYYY
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Achievement({
    this.id,
    required this.studentId,
    required this.fromSurah,
    required this.toSurah,
    required this.fromVerse,
    required this.toVerse,
    this.note,
    this.achievementType = 'normal',
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      studentId: json['student_id'],
      fromSurah: json['from_surah'],
      toSurah: json['to_surah'],
      fromVerse: json['from_verse'],
      toVerse: json['to_verse'],
      note: json['note'],
      achievementType: json['achievement_type'] ?? 'normal',
      date: json['date'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'from_surah': fromSurah,
      'to_surah': toSurah,
      'from_verse': fromVerse,
      'to_verse': toVerse,
      'note': note,
      'achievement_type': achievementType,
      'date': date,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Achievement copyWith({
    int? id,
    int? studentId,
    int? fromSurah,
    int? toSurah,
    int? fromVerse,
    int? toVerse,
    String? note,
    String? achievementType,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fromSurah: fromSurah ?? this.fromSurah,
      toSurah: toSurah ?? this.toSurah,
      fromVerse: fromVerse ?? this.fromVerse,
      toVerse: toVerse ?? this.toVerse,
      note: note ?? this.note,
      achievementType: achievementType ?? this.achievementType,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get surah name
  String getFromSurahName() {
    final surah = getSurahByNumber(fromSurah);
    return surah?.name ?? 'سورة $fromSurah';
  }

  String getToSurahName() {
    final surah = getSurahByNumber(toSurah);
    return surah?.name ?? 'سورة $toSurah';
  }

  // Helper method to get achievement type in Arabic
  String getAchievementTypeArabic() {
    switch (achievementType) {
      case 'normal':
        return 'حفظ';
      case 'small':
        return 'مراجعة صغيرة';
      case 'big':
        return 'مراجعة كبيرة';
      default:
        return achievementType;
    }
  }
}
