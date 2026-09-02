import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/reports/shared.dart';

class OverallSummary1 {
  final StatItem reinforcementLog;
  final StatItem reviewPages;
  final StatItem memorizationPages;
  final StatItem studyCircleStudentCount;
  OverallSummary1({
    required this.reinforcementLog,
    required this.reviewPages,
    required this.memorizationPages,
    required this.studyCircleStudentCount,
  });
  factory OverallSummary1.fromJson(Map<String, dynamic> json) {
    return OverallSummary1(
      reinforcementLog: StatItem.fromJson(json['reinforcementLog']),
      reviewPages: StatItem.fromJson(json['reviewPages']),
      memorizationPages: StatItem.fromJson(json['memorizationPages']),
      studyCircleStudentCount: StatItem.fromJson(
        json['studyCircleStudentCount'],
      ),
    );
  }
}
