import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import '../system/new_models/charts/chart_data_models.dart';
import 'chart_screen.dart';

class AttendanceChartScreen extends StatelessWidget {
  const AttendanceChartScreen({super.key});

  final String _dummyData = '''
  [
    {
      "studentId": "1",
      "studentName": "Ali",
      "lectureId": "101",
      "lectureName": "Quran",
      "date": "2024-06-01",
      "attendedDays": 18,
      "absentDays": 2,
      "lateDays": 1
    },
    {
      "studentId": "2",
      "studentName": "Sara",
      "lectureId": "101",
      "lectureName": "Quran",
      "date": "2024-06-01",
      "attendedDays": 20,
      "absentDays": 0,
      "lateDays": 0
    },
    {
      "studentId": "1",
      "studentName": "Ali",
      "lectureId": "102",
      "lectureName": "Tajweed",
      "date": "2024-06-02",
      "attendedDays": 15,
      "absentDays": 5,
      "lateDays": 1
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    final data = (json.decode(_dummyData) as List<dynamic>)
        .map((json) => AttendanceRecord.fromJson(json))
        .toList();

    return ChartScreen<AttendanceRecord>(
      title: 'الحضور',
      tag: 'stat2',
      data: data,
      seriesConfigs: [
        ChartSeriesConfig(
          name: 'الحضور',
          color: Theme.of(context).colorScheme.primary,
          valueMapper: (data) => data.attendedDays.toDouble(),
          seriesBuilder: (data, color) => ColumnSeries<ChartEntry, String>(
            name: 'الحضور',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date.toString().split(' ')[0],
            yValueMapper: (entry, _) => entry.value,
            color: color,
          ),
        ),
        ChartSeriesConfig(
          name: 'الغياب',
          color: Theme.of(context).colorScheme.error,
          valueMapper: (data) => data.absentDays.toDouble(),
          seriesBuilder: (data, color) => ColumnSeries<ChartEntry, String>(
            name: 'الغياب',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date.toString().split(' ')[0],
            yValueMapper: (entry, _) => entry.value,
            color: color,
          ),
        ),
        ChartSeriesConfig(
          name: 'التأخير',
          color: Theme.of(context).colorScheme.secondary,
          valueMapper: (data) => data.lateDays.toDouble(),
          seriesBuilder: (data, color) => ColumnSeries<ChartEntry, String>(
            name: 'التأخير',
            dataSource: data,
            xValueMapper: (entry, _) => entry.date.toString().split(' ')[0],
            yValueMapper: (entry, _) => entry.value,
            color: color,
          ),
        ),
      ],
      axisConfig: ChartAxisConfig(
        xAxis: CategoryAxis(
          labelRotation: 45,
          labelIntersectAction: AxisLabelIntersectAction.rotate45,
        ),
        yAxisLabel: 'الأيام',
      ),
    );
  }
}
