import 'package:flutter/material.dart';

enum SenderRole {
  teacher,
  supervisor,
  president;

  String get displayName {
    switch (this) {
      case SenderRole.teacher:
        return 'معلم';
      case SenderRole.supervisor:
        return 'مشرف';
      case SenderRole.president:
        return 'رئيس';
    }
  }

  Color get color {
    switch (this) {
      case SenderRole.teacher:
        return const Color(0xFF4CAF50); // Green
      case SenderRole.supervisor:
        return const Color(0xFF2196F3); // Blue
      case SenderRole.president:
        return const Color(0xFFE53935); // Red
    }
  }

  static SenderRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return SenderRole.teacher;
      case 'supervisor':
        return SenderRole.supervisor;
      case 'president':
        return SenderRole.president;
      default:
        return SenderRole.teacher;
    }
  }

  String toJson() => name;
}

class Message {
  final int? id;
  final int? senderId;
  final String senderName;
  final SenderRole senderRole;
  final String message;
  final DateTime? createdAt;

  Message({
    this.id,
    this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String,
      senderRole: SenderRole.fromString(json['sender_role'] as String),
      message: json['message'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sender_role': senderRole.toJson(),
    };
  }

  String getFormattedTime() {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
  }
}

class MessageList {
  final List<Message> messages;
  final int total;

  MessageList({
    required this.messages,
    required this.total,
  });

  factory MessageList.fromJson(Map<String, dynamic> json) {
    return MessageList(
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
