// Data Model Classes
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/shared.dart';

class OverallSummary3 {
  final StatItem attendanceDays;
  final StatItem memorizationPagesCount;
  final StatItem memorizationDegreeAverage;
  final StatItem attendanceDaysInCourse;
  final StatItem consistencyRatio;
  final StatItem reviewPagesCount;
  final StatItem reviewAmountWithParts;
  final StatItem reviewDegreeAverage;

  OverallSummary3({
    required this.attendanceDays,
    required this.memorizationPagesCount,
    required this.memorizationDegreeAverage,
    required this.attendanceDaysInCourse,
    required this.consistencyRatio,
    required this.reviewPagesCount,
    required this.reviewAmountWithParts,
    required this.reviewDegreeAverage,
  });

  factory OverallSummary3.fromJson(Map<String, dynamic> json) {
    return OverallSummary3(
      attendanceDays: StatItem.fromJson(json['attendanceDays']),
      memorizationPagesCount: StatItem.fromJson(json['memorizationPagesCount']),
      memorizationDegreeAverage: StatItem.fromJson(
        json['memorizationDegreeAverage'],
      ),
      attendanceDaysInCourse: StatItem.fromJson(json['attendanceDaysInCourse']),
      consistencyRatio: StatItem.fromJson(json['consistencyRatio']),
      reviewPagesCount: StatItem.fromJson(json['reviewPagesCount']),
      reviewAmountWithParts: StatItem.fromJson(json['reviewAmountWithParts']),
      reviewDegreeAverage: StatItem.fromJson(json['reviewDegreeAverage']),
    );
  }
}
