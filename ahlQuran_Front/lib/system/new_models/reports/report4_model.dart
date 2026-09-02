// File: report4_model.dart
import 'dart:core';
import 'shared.dart';

class ReportDataModel {
  final ReportData reportData;
  final CurriculumSchedule curriculumSchedule;

  ReportDataModel({required this.reportData, required this.curriculumSchedule});

  factory ReportDataModel.fromJson(Map<String, dynamic> json) {
    return ReportDataModel(
      reportData: ReportData.fromJson(json['report_data']),
      curriculumSchedule: CurriculumSchedule.fromJson(
        json['curriculum_schedule'],
      ),
    );
  }
}

class ReportData {
  final HeaderInfo headerInfo;
  final SummaryReport summaryReport;
  final List<DetailedReport> detailedReport;

  ReportData({
    required this.headerInfo,
    required this.summaryReport,
    required this.detailedReport,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      headerInfo: HeaderInfo.fromJson(json['header_info']),
      summaryReport: SummaryReport.fromJson(json['summary_report']),
      detailedReport: (json['detailed_report'] as List)
          .map((e) => DetailedReport.fromJson(e))
          .toList(),
    );
  }
}

class SummaryReport {
  final int? totalStudents;
  final int? studentsCountTotal;
  final int? memorizationPartsCount;
  final int attendanceDaysCount;
  final int reviewDaysCount;
  final double? memorizationPartsReview;
  final double? memorizationPartsFixation;
  final int disciplinesLessons;
  final int moshafReadingLessons;
  final double memorizationLessonsTotal;
  final double collectiveListeningPages;

  SummaryReport({
    this.totalStudents,
    this.studentsCountTotal,
    this.memorizationPartsCount,
    required this.attendanceDaysCount,
    required this.reviewDaysCount,
    this.memorizationPartsReview,
    this.memorizationPartsFixation,
    required this.disciplinesLessons,
    required this.moshafReadingLessons,
    required this.memorizationLessonsTotal,
    required this.collectiveListeningPages,
  });

  factory SummaryReport.fromJson(Map<String, dynamic> json) {
    return SummaryReport(
      totalStudents: json['total_students'],
      studentsCountTotal: json['students_count_total'],
      memorizationPartsCount: json['memorization_parts_count'],
      attendanceDaysCount: json['attendance_days_count'],
      reviewDaysCount: json['review_days_count'],
      memorizationPartsReview:
          (json['memorization_parts_review'] as num?)?.toDouble(),
      memorizationPartsFixation:
          (json['memorization_parts_تثبيت'] as num?)?.toDouble(),
      disciplinesLessons: json['disciplines_lessons'],
      moshafReadingLessons: json['moshaf_reading_lessons'],
      memorizationLessonsTotal:
          (json['memorization_lessons_total'] as num).toDouble(),
      collectiveListeningPages:
          (json['collective_listening_pages'] as num).toDouble(),
    );
  }
}

class MetricData {
  final double avg;
  final double count;
  final double value;

  MetricData({required this.avg, required this.count, required this.value});

  factory MetricData.fromJson(Map<String, dynamic> json) {
    return MetricData(
      avg: (json['avg'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetailedReport {
  final int id;
  final String studentName;

  final MetricData memorization;
  final MetricData review;
  final MetricData fixation;

  final double attendancePercentage;
  final int days;

  DetailedReport({
    required this.id,
    required this.studentName,
    required this.memorization,
    required this.review,
    required this.fixation,
    required this.attendancePercentage,
    required this.days,
  });

  factory DetailedReport.fromJson(Map<String, dynamic> json) {
    return DetailedReport(
      id: json['id'] as int,
      studentName: json['student_name'] ?? '',
      memorization: MetricData(
        avg: (json['memorization_parts_avg'] as num?)?.toDouble() ?? 0.0,
        count: 0.0,
        value: (json['memorization_pages'] as num?)?.toDouble() ?? 0.0,
      ),
      review: MetricData(
        avg: (json['review_parts'] as num?)?.toDouble() ?? 0.0,
        count: 0.0,
        value: (json['review_pages'] as num?)?.toDouble() ?? 0.0,
      ),
      fixation: MetricData(
        avg: (json['fixation_parts'] as num?)?.toDouble() ?? 0.0,
        count: 0.0,
        value: (json['fixation_pages'] as num?)?.toDouble() ?? 0.0,
      ),
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
      days: 0,
    );
  }
}
