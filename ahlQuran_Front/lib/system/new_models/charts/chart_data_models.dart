//TODO
class StudentProgressData {
  final String studentId;
  final String studentName;
  final String lectureId;
  final String lectureName;
  final DateTime date;
  final double memorizedPages;
  final double minorRevisionPages;
  final double majorRevisionPages;

  StudentProgressData({
    required this.studentId,
    required this.studentName,
    required this.lectureId,
    required this.lectureName,
    required this.date,
    required this.memorizedPages,
    required this.minorRevisionPages,
    required this.majorRevisionPages,
  });

  factory StudentProgressData.fromJson(Map<String, dynamic> json) {
    return StudentProgressData(
      studentId: json['studentId'],
      studentName: json['studentName'],
      lectureId: json['lectureId'],
      lectureName: json['lectureName'],
      date: DateTime.parse(json['date']),
      memorizedPages: (json['memorizedPages'] as num).toDouble(),
      minorRevisionPages: (json['minorRevisionPages'] as num).toDouble(),
      majorRevisionPages: (json['majorRevisionPages'] as num).toDouble(),
    );
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String lectureId;
  final String lectureName;
  final DateTime date;
  final int attendedDays;
  final int absentDays;
  final int lateDays;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.lectureId,
    required this.lectureName,
    required this.date,
    required this.attendedDays,
    required this.absentDays,
    required this.lateDays,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'],
      studentName: json['studentName'],
      lectureId: json['lectureId'],
      lectureName: json['lectureName'],
      date: DateTime.parse(json['date']),
      attendedDays: json['attendedDays'],
      absentDays: json['absentDays'],
      lateDays: json['lateDays'],
    );
  }
}

class PerformanceRecord {
  final String studentId;
  final String studentName;
  final String lectureId;
  final String lectureName;
  final DateTime date;
  final double memorizationScore;
  final double revisionScore;
  final double reinforcementScore;

  PerformanceRecord({
    required this.studentId,
    required this.studentName,
    required this.lectureId,
    required this.lectureName,
    required this.date,
    required this.memorizationScore,
    required this.revisionScore,
    required this.reinforcementScore,
  });

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) {
    return PerformanceRecord(
      studentId: json['studentId'],
      studentName: json['studentName'],
      lectureId: json['lectureId'],
      lectureName: json['lectureName'],
      date: DateTime.parse(json['date']),
      memorizationScore: (json['memorizationScore'] as num).toDouble(),
      revisionScore: (json['revisionScore'] as num).toDouble(),
      reinforcementScore: (json['reinforcementScore'] as num).toDouble(),
    );
  }
}

class ChartEntry {
  final DateTime date;
  final String category;
  final double value;

  ChartEntry(this.date, this.category, this.value);
}
