class AttendanceRecord {
  final int id;
  final StudentContext student;
  final String date;
  final String status;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.student,
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      student: StudentContext.fromJson(json['student']),
      date: json['date'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  String get statusArabic {
    switch (status.toLowerCase()) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      case 'excused':
        return 'معذور';
      default:
        return status;
    }
  }

  bool get isPresent => status.toLowerCase() == 'present';
}

class StudentContext {
  final int id;
  final String name;

  StudentContext({required this.id, required this.name});

  factory StudentContext.fromJson(Map<String, dynamic> json) {
    return StudentContext(id: json['id'], name: json['name']);
  }
}

class PaginatedAttendanceResponse {
  final List<AttendanceRecord> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedAttendanceResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedAttendanceResponse(
      items: (json['items'] as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      totalPages: json['total_pages'],
    );
  }
}
