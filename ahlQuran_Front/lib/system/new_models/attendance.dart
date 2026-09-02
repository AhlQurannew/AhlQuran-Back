import 'package:flutter/material.dart';

class Attendance {
  final int? id;
  final int studentId;
  final String date; // Format: DD-MM-YYYY
  final String status; // "present", "late", "absent", "excused"
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    this.id,
    required this.studentId,
    required this.date,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      date: json['date'],
      status: json['status'],
      notes: json['notes'],
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
      'date': date,
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Get Arabic status text
  String getStatusArabic() {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'late':
        return 'متأخر';
      case 'absent':
        return 'غائب';
      case 'excused':
        return 'غائب بعذر';
      default:
        return status;
    }
  }

  // Get status color
  Color getStatusColor() {
    switch (status) {
      case 'present':
        return const Color(0xFF4CAF50); // Green
      case 'late':
        return const Color(0xFFFFA726); // Orange
      case 'absent':
        return const Color(0xFFEF5350); // Red
      case 'excused':
        return const Color(0xFF42A5F5); // Blue
      default:
        return Colors.grey;
    }
  }

  Attendance copyWith({
    int? id,
    int? studentId,
    String? date,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
