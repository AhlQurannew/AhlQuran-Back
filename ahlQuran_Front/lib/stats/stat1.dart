import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../system/new_models/charts/chart_data_models.dart';
import 'chart_screen.dart';

class StudentProgressChartScreen extends StatelessWidget {
  const StudentProgressChartScreen({super.key});

  final String _dummyData = '''
  [
    {
      "studentId": "1",
      "studentName": "Ali",
      "lectureId": "101",
      "lectureName": "Quran",
      "date": "2024-06-01",
      "memorizedPages": 5,
      "minorRevisionPages": 2,
      "majorRevisionPages": 1
    },
    {
      "studentId": "1",
      "studentName": "Ali",
      "lectureId": "101",
      "lectureName": "Quran",
      "date": "2024-06-02",
      "memorizedPages": 6,
      "minorRevisionPages": 3,
      "majorRevisionPages": 2
    },
    {
      "studentId": "2",
      "studentName": "Sara",
      "lectureId": "102",
      "lectureName": "Tajweed",
      "date": "2024-06-01",
      "memorizedPages": 4,
      "minorRevisionPages": 1,
      "majorRevisionPages": 0
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    final data = (json.decode(_dummyData) as List<dynamic>)
        .map((json) => StudentProgressData.fromJson(json))
        .toList();

    return ChartScreen<StudentProgressData>(
      title: 'تقدم الطالب',
      tag: 'stat1',
      data: data,
      seriesConfigs: [
        ChartSeriesConfig(
          name: 'الحفظ',
          color: Theme.of(context).colorScheme.primary,
          valueMapper: (data) => data.memorizedPages,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'الحفظ',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ),
        ChartSeriesConfig(
          name: 'مراجعة صغرى',
          color: Theme.of(context).colorScheme.secondary,
          valueMapper: (data) => data.minorRevisionPages,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'مراجعة صغرى',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ),
        ChartSeriesConfig(
          name: 'مراجعة كبرى',
          color: Theme.of(context).colorScheme.error,
          valueMapper: (data) => data.majorRevisionPages,
          seriesBuilder: (data, color) => LineSeries<ChartEntry, DateTime>(
            name: 'مراجعة كبرى',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date,
            yValueMapper: (entry, _) => entry.value,
            color: color,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ),
      ],
      axisConfig: ChartAxisConfig(
        xAxis: DateTimeAxis(
          dateFormat: DateFormat.MMMd('ar'),
          intervalType: DateTimeIntervalType.days,
        ),
        yAxisLabel: 'عدد الصفحات',
      ),
    );
  }
}
