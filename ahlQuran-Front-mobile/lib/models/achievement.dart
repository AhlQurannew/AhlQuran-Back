import '../helpers/quran_data.dart';

class AchievementRecord {
  final int id;
  final StudentContext student;
  final int fromSurah;
  final int toSurah;
  final int fromVerse;
  final int toVerse;
  final String? note;
  final String achievementType;
  final String date;

  AchievementRecord({
    required this.id,
    required this.student,
    required this.fromSurah,
    required this.toSurah,
    required this.fromVerse,
    required this.toVerse,
    this.note,
    required this.achievementType,
    required this.date,
  });

  factory AchievementRecord.fromJson(Map<String, dynamic> json) {
    return AchievementRecord(
      id: json['id'],
      student: StudentContext.fromJson(json['student']),
      fromSurah: json['from_surah'],
      toSurah: json['to_surah'],
      fromVerse: json['from_verse'],
      toVerse: json['to_verse'],
      note: json['note'],
      achievementType: json['achievement_type'],
      date: json['date'],
    );
  }

  String get typeArabic {
    switch (achievementType.toLowerCase()) {
      case 'normal':
        return 'حفظ';
      case 'small':
        return 'مراجعة صغرى';
      case 'big':
        return 'مراجعة كبرى';
      default:
        return achievementType;
    }
  }

  String get surahRange {
    if (fromSurah == toSurah) {
      return QuranData.getSurahNameArabic(fromSurah);
    }
    return '${QuranData.getSurahNameArabic(fromSurah)} - ${QuranData.getSurahNameArabic(toSurah)}';
  }

  String getSurahName(int surahNumber) {
    return QuranData.getSurahNameArabic(surahNumber);
  }
}

class StudentContext {
  final int id;
  final String name;

  StudentContext({required this.id, required this.name});

  factory StudentContext.fromJson(Map<String, dynamic> json) {
    return StudentContext(id: json['id'], name: json['name']);
  }
}

class PaginatedAchievementsResponse {
  final List<AchievementRecord> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedAchievementsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedAchievementsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedAchievementsResponse(
      items: (json['items'] as List)
          .map((item) => AchievementRecord.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      totalPages: json['total_pages'],
    );
  }
}
