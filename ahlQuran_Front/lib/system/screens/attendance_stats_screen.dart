import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:fl_chart/fl_chart.dart';
import '../new_models/attendance.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class AttendanceStatsScreen extends StatefulWidget {
  const AttendanceStatsScreen({super.key});

  @override
  State<AttendanceStatsScreen> createState() => _AttendanceStatsScreenState();
}

class _AttendanceStatsScreenState extends State<AttendanceStatsScreen> {
  String? lectureName;
  String? studentName;
  int? studentId;
  String? startDate;
  String? endDate;
  List<Attendance> attendances = [];
  bool isLoading = true;

  int presentCount = 0;
  int lateCount = 0;
  int absentCount = 0;
  int excusedCount = 0;

  @override
  void initState() {
    super.initState();

    // Get parameters from Get.parameters
    final parameters = Get.parameters;
    lectureName = parameters['lectureName'] ?? '';
    studentName = parameters['studentName'] ?? '';
    studentId = int.tryParse(parameters['studentId'] ?? '');
    startDate = parameters['startDate'] ?? '';
    endDate = parameters['endDate'] ?? '';

    dev.log('Student ID: $studentId, Start: $startDate, End: $endDate');

    _loadAttendances();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(10);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  Future<void> _loadAttendances() async {
    if (studentId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.fetchList(
        '${ApiEndpoints.getStudents}$studentId/attendance',
        Attendance.fromJson,
      );

      // Filter attendances by date range
      final filteredAttendances = response.where((attendance) {
        if (startDate == null || endDate == null) return true;

        try {
          final attDate = _parseDate(attendance.date);
          final start = _parseDate(startDate!);
          final end = _parseDate(endDate!);

          return attDate.isAfter(start.subtract(const Duration(days: 1))) &&
              attDate.isBefore(end.add(const Duration(days: 1)));
        } catch (e) {
          dev.log('Error parsing date: $e');
          return false;
        }
      }).toList();

      // Count each status type
      presentCount =
          filteredAttendances.where((a) => a.status == 'present').length;
      lateCount = filteredAttendances.where((a) => a.status == 'late').length;
      absentCount =
          filteredAttendances.where((a) => a.status == 'absent').length;
      excusedCount =
          filteredAttendances.where((a) => a.status == 'excused').length;

      setState(() {
        attendances = filteredAttendances;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading attendances: $e');
      setState(() {
        attendances = [];
        isLoading = false;
      });
    }
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "إحصائيات المواظبة",
        child: Column(
          children: [
            _buildHeaderBar(theme),
            const SizedBox(height: 16),
            _buildInfoBar(theme),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildChartSection(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDEB059),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'إحصائيات المواظبة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildInfoCard('الطالب', studentName ?? '', theme),
          _buildInfoCard('الحلقة', lectureName ?? '', theme),
          _buildInfoCard('من', startDate ?? '', theme),
          _buildInfoCard('إلى', endDate ?? '', theme),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'عدد الأيام حسب حالة المواظبة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _buildBarChart(),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxY = [presentCount, lateCount, absentCount, excusedCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final roundedMaxY = (maxY / 5).ceil() * 5.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: roundedMaxY > 0 ? roundedMaxY : 5,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              switch (group.x) {
                case 0:
                  label = 'حاضر';
                  break;
                case 1:
                  label = 'متأخر';
                  break;
                case 2:
                  label = 'غائب';
                  break;
                case 3:
                  label = 'غائب بعذر';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                '$label\n${rod.toY.toInt()} يوم',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'حاضر',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  case 1:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'متأخر',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  case 2:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'غائب',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  case 3:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'غائب بعذر',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: roundedMaxY > 0 ? roundedMaxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade400, width: 1),
            left: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: presentCount.toDouble(),
                color: const Color(0xFF4CAF50), // Green for present
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: lateCount.toDouble(),
                color: const Color(0xFFFFA726), // Orange for late
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: absentCount.toDouble(),
                color: const Color(0xFFEF5350), // Red for absent
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: excusedCount.toDouble(),
                color: const Color(0xFF42A5F5), // Blue for excused
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('حاضر', const Color(0xFF4CAF50), presentCount),
        _buildLegendItem('متأخر', const Color(0xFFFFA726), lateCount),
        _buildLegendItem('غائب', const Color(0xFFEF5350), absentCount),
        _buildLegendItem('غائب بعذر', const Color(0xFF42A5F5), excusedCount),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count يوم',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
