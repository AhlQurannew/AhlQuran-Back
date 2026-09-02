import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../system/new_models/charts/chart_data_models.dart';
import 'chart_screen.dart';

class PerformanceChartScreen extends StatelessWidget {
  const PerformanceChartScreen({super.key});

  final String _dummyData = '''
[
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-06-01",
    "memorizationScore": 85,
    "revisionScore": 90,
    "reinforcementScore": 80
  },
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-06-08",
    "memorizationScore": 88,
    "revisionScore": 92,
    "reinforcementScore": 85
  },
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-06-15",
    "memorizationScore": 90,
    "revisionScore": 85,
    "reinforcementScore": 87
  },
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-06-22",
    "memorizationScore": 92,
    "revisionScore": 88,
    "reinforcementScore": 90
  },
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-06-29",
    "memorizationScore": 93,
    "revisionScore": 90,
    "reinforcementScore": 91
  },
  {
    "studentId": "1",
    "studentName": "Ali",
    "lectureId": "101",
    "lectureName": "Quran",
    "date": "2024-07-06",
    "memorizationScore": 94,
    "revisionScore": 91,
    "reinforcementScore": 92
  },
  {
    "studentId": "2",
    "studentName": "Sara",
    "lectureId": "102",
    "lectureName": "Tajweed",
    "date": "2024-06-08",
    "memorizationScore": 92,
    "revisionScore": 88,
    "reinforcementScore": 90
  },
  {
    "studentId": "2",
    "studentName": "Sara",
    "lectureId": "102",
    "lectureName": "Tajweed",
    "date": "2024-06-15",
    "memorizationScore": 6,
    "revisionScore": 44,
    "reinforcementScore": 96
  }
]
''';

  @override
  Widget build(BuildContext context) {
    final data = (json.decode(_dummyData) as List<dynamic>)
        .map((json) => PerformanceRecord.fromJson(json))
        .toList();

    return ChartScreen<PerformanceRecord>(
      title: 'الأداء',
      tag: 'stat3',
      data: data,
      seriesConfigs: [
        ChartSeriesConfig(
          name: 'الحفظ',
          color: Theme.of(context).colorScheme.primary,
          valueMapper: (data) => data.memorizationScore,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'الحفظ',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
            ),
            width: 2,
            animationDuration: 1000,
          ),
        ),
        ChartSeriesConfig(
          name: 'المراجعة',
          color: Theme.of(context).colorScheme.secondary,
          valueMapper: (data) => data.revisionScore,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'المراجعة',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
            ),
            width: 2,
            animationDuration: 1000,
          ),
        ),
        ChartSeriesConfig(
          name: 'تثبيت',
          color: Theme.of(context).colorScheme.error,
          valueMapper: (data) => data.reinforcementScore,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'تثبيت',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
            ),
            width: 2,
            animationDuration: 1000,
          ),
        ),
      ],
      axisConfig: ChartAxisConfig(
        xAxis: DateTimeAxis(
          dateFormat: DateFormat.yMMMd('ar'),
          intervalType: DateTimeIntervalType.days,
          interval: 7,
          title: AxisTitle(text: 'التاريخ'),
        ),
        yAxisLabel: 'الدرجة',
      ),
    );
  }
}
