import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:fl_chart/fl_chart.dart';
import '../new_models/achievement.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../data/quran_page_data.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class AchievementStatsScreen extends StatefulWidget {
  const AchievementStatsScreen({super.key});

  @override
  State<AchievementStatsScreen> createState() => _AchievementStatsScreenState();
}

class _AchievementStatsScreenState extends State<AchievementStatsScreen> {
  String? lectureName;
  String? studentName;
  int? studentId;
  String? startDate;
  String? endDate;
  List<Achievement> achievements = [];
  bool isLoading = true;

  double normalPages = 0;
  double smallPages = 0;
  double bigPages = 0;

  @override
  void initState() {
    super.initState();

    // Get parameters from Get.parameters (already decoded by GetX)
    final parameters = Get.parameters;
    lectureName = parameters['lectureName'] ?? '';
    studentName = parameters['studentName'] ?? '';
    studentId = int.tryParse(parameters['studentId'] ?? '');
    startDate = parameters['startDate'] ?? '';
    endDate = parameters['endDate'] ?? '';

    dev.log('Student ID: $studentId, Start: $startDate, End: $endDate');

    _loadAchievements();

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

  Future<void> _loadAchievements() async {
    if (studentId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.fetchList(
        '${ApiEndpoints.getStudents}$studentId/achievements',
        Achievement.fromJson,
      );

      // Filter achievements by date range
      final filteredAchievements = response.where((achievement) {
        if (startDate == null || endDate == null) return true;

        try {
          final achDate = _parseDate(achievement.date);
          final start = _parseDate(startDate!);
          final end = _parseDate(endDate!);

          return achDate.isAfter(start.subtract(const Duration(days: 1))) &&
              achDate.isBefore(end.add(const Duration(days: 1)));
        } catch (e) {
          dev.log('Error parsing date: $e');
          return false;
        }
      }).toList();

      // Calculate pages for each type
      normalPages = _calculatePages(filteredAchievements
          .where((a) => a.achievementType == 'normal')
          .toList());
      smallPages = _calculatePages(filteredAchievements
          .where((a) => a.achievementType == 'small')
          .toList());
      bigPages = _calculatePages(filteredAchievements
          .where((a) => a.achievementType == 'big')
          .toList());

      setState(() {
        achievements = filteredAchievements;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading achievements: $e');
      setState(() {
        achievements = [];
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

  double _calculatePages(List<Achievement> achievements) {
    double totalPages = 0;

    for (var achievement in achievements) {
      final startPage = QuranPageData.getPageNumber(
        achievement.fromSurah,
        achievement.fromVerse,
      );
      final endPage = QuranPageData.getPageNumber(
        achievement.toSurah,
        achievement.toVerse,
      );

      if (startPage != null && endPage != null) {
        // Add 1 because if you memorize from page 1 to page 1, that's 1 page
        totalPages += (endPage - startPage + 1);
      }
    }

    return totalPages;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "إحصائيات الإنجاز",
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
            'إحصائيات الإنجاز',
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
            'عدد الصفحات حسب نوع الإنجاز',
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
    final maxY =
        [normalPages, smallPages, bigPages].reduce((a, b) => a > b ? a : b);
    final roundedMaxY = (maxY / 10).ceil() * 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: roundedMaxY > 0 ? roundedMaxY : 10,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              switch (group.x) {
                case 0:
                  label = 'حفظ';
                  break;
                case 1:
                  label = 'مراجعة صغرى';
                  break;
                case 2:
                  label = 'مراجعة كبرى';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(1)} صفحة',
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
              reservedSize: 60, // Increased from default to accommodate text
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'حفظ',
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
                        'مراجعة صغرى',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    );
                  case 2:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'مراجعة كبرى',
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
          horizontalInterval: roundedMaxY > 0 ? roundedMaxY / 5 : 2,
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
                toY: normalPages,
                color: const Color(0xFF4DB6AC), // Mint green for حفظ
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
                toY: smallPages,
                color: const Color(0xFFDEB059), // Golden for مراجعة صغرى
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
                toY: bigPages,
                color: Colors.grey.shade600, // Gray for مراجعة كبرى
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('حفظ', const Color(0xFF4DB6AC), normalPages),
        const SizedBox(width: 24),
        _buildLegendItem('مراجعة صغرى', const Color(0xFFDEB059), smallPages),
        const SizedBox(width: 24),
        _buildLegendItem('مراجعة كبرى', Colors.grey.shade600, bigPages),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double pages) {
    return Row(
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
          '$label: ${pages.toStringAsFixed(1)} صفحة',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
