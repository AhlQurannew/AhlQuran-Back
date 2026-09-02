import 'package:flutter/material.dart';

class TeacherAttendance {
  final int? id;
  final int teacherId;
  final String date; // Format: DD-MM-YYYY
  final String status; // "present", "late", "absent", "excused"
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeacherAttendance({
    this.id,
    required this.teacherId,
    required this.date,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherAttendance.fromJson(Map<String, dynamic> json) {
    return TeacherAttendance(
      id: json['id'],
      teacherId: json['teacher_id'],
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
      'teacher_id': teacherId,
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

  TeacherAttendance copyWith({
    int? id,
    int? teacherId,
    String? date,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherAttendance(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
