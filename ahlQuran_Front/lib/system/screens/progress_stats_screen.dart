import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../new_models/achievement.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../data/quran_page_data.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class ProgressStatsScreen extends StatefulWidget {
  const ProgressStatsScreen({super.key});

  @override
  State<ProgressStatsScreen> createState() => _ProgressStatsScreenState();
}

class _ProgressStatsScreenState extends State<ProgressStatsScreen> {
  String? lectureName;
  String? studentName;
  int? studentId;
  String? startDate;
  String? endDate;
  List<Achievement> achievements = [];
  bool isLoading = true;

  Map<DateTime, double> dailyNormalPages = {};
  Map<DateTime, double> dailySmallPages = {};
  Map<DateTime, double> dailyBigPages = {};
  List<FlSpot> normalSpots = [];
  List<FlSpot> smallSpots = [];
  List<FlSpot> bigSpots = [];

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

      // Filter achievements by date range (all types)
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

      // Calculate pages per day for each type
      _calculateDailyPages(filteredAchievements);

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

  void _calculateDailyPages(List<Achievement> achievements) {
    dailyNormalPages.clear();
    dailySmallPages.clear();
    dailyBigPages.clear();

    for (var achievement in achievements) {
      final date = _parseDate(achievement.date);
      final pages = _calculatePages(achievement);

      if (achievement.achievementType == 'normal') {
        dailyNormalPages[date] = (dailyNormalPages[date] ?? 0) + pages;
      } else if (achievement.achievementType == 'small') {
        dailySmallPages[date] = (dailySmallPages[date] ?? 0) + pages;
      } else if (achievement.achievementType == 'big') {
        dailyBigPages[date] = (dailyBigPages[date] ?? 0) + pages;
      }
    }

    // Create chart spots for each type
    if (dailyNormalPages.isNotEmpty ||
        dailySmallPages.isNotEmpty ||
        dailyBigPages.isNotEmpty) {
      // Get all dates and sort them
      final allDates = <DateTime>{
        ...dailyNormalPages.keys,
        ...dailySmallPages.keys,
        ...dailyBigPages.keys,
      }.toList()
        ..sort();

      if (allDates.isNotEmpty) {
        final firstDate = allDates.first;

        // Create spots for normal (حفظ)
        normalSpots = allDates
            .map((date) {
              final daysDiff = date.difference(firstDate).inDays.toDouble();
              final pages = dailyNormalPages[date] ?? 0;
              return FlSpot(daysDiff, pages);
            })
            .where((spot) => spot.y > 0)
            .toList();

        // Create spots for small (مراجعة صغرى)
        smallSpots = allDates
            .map((date) {
              final daysDiff = date.difference(firstDate).inDays.toDouble();
              final pages = dailySmallPages[date] ?? 0;
              return FlSpot(daysDiff, pages);
            })
            .where((spot) => spot.y > 0)
            .toList();

        // Create spots for big (مراجعة كبرى)
        bigSpots = allDates
            .map((date) {
              final daysDiff = date.difference(firstDate).inDays.toDouble();
              final pages = dailyBigPages[date] ?? 0;
              return FlSpot(daysDiff, pages);
            })
            .where((spot) => spot.y > 0)
            .toList();
      }
    }
  }

  double _calculatePages(Achievement achievement) {
    final startPage = QuranPageData.getPageNumber(
      achievement.fromSurah,
      achievement.fromVerse,
    );
    final endPage = QuranPageData.getPageNumber(
      achievement.toSurah,
      achievement.toVerse,
    );

    if (startPage != null && endPage != null) {
      return (endPage - startPage + 1).toDouble();
    }
    return 0;
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
        title: "منحنى تطور الإنجاز",
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
            'منحنى تطور الإنجاز',
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
    if (normalSpots.isEmpty && smallSpots.isEmpty && bigSpots.isEmpty) {
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
        child: const Center(
          child: Text(
            'لا توجد بيانات في هذه الفترة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

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
            'منحنى تطور الإنجاز',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('حفظ', const Color(0xFF4DB6AC)),
        const SizedBox(width: 24),
        _buildLegendItem('مراجعة صغرى', const Color(0xFFDEB059)),
        const SizedBox(width: 24),
        _buildLegendItem('مراجعة كبرى', Colors.grey),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    // Get all spots to calculate max values
    final allSpots = [...normalSpots, ...smallSpots, ...bigSpots];
    if (allSpots.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final maxY = allSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final roundedMaxY = (maxY / 5).ceil() * 5.0;
    final maxX = allSpots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

    // Get first date for tooltip
    final allDates = <DateTime>{
      ...dailyNormalPages.keys,
      ...dailySmallPages.keys,
      ...dailyBigPages.keys,
    }.toList()
      ..sort();
    final firstDate = allDates.first;

    // Build line bars data
    final lineBars = <LineChartBarData>[];

    // Add normal line (حفظ - mint)
    if (normalSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: normalSpots,
          isCurved: true,
          color: const Color(0xFF4DB6AC),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF4DB6AC),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Add small line (مراجعة صغرى - golden)
    if (smallSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: smallSpots,
          isCurved: true,
          color: const Color(0xFFDEB059),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFFDEB059),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Add big line (مراجعة كبرى - gray)
    if (bigSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: bigSpots,
          isCurved: true,
          color: Colors.grey,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.grey,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: roundedMaxY > 0 ? roundedMaxY / 5 : 1,
          verticalInterval: maxX > 10 ? maxX / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: maxX > 10 ? (maxX / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final date = firstDate.add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: roundedMaxY > 0 ? roundedMaxY / 5 : 1,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade400, width: 1),
            left: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
        ),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: roundedMaxY > 0 ? roundedMaxY : 10,
        lineBarsData: lineBars,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = firstDate.add(Duration(days: barSpot.x.toInt()));
                String type = '';
                Color color = Colors.white;

                if (barSpot.barIndex == 0 && normalSpots.isNotEmpty) {
                  type = 'حفظ';
                  color = const Color(0xFF4DB6AC);
                } else if ((barSpot.barIndex == 1 && normalSpots.isNotEmpty) ||
                    (barSpot.barIndex == 0 && normalSpots.isEmpty)) {
                  type = 'مراجعة صغرى';
                  color = const Color(0xFFDEB059);
                } else {
                  type = 'مراجعة كبرى';
                  color = Colors.grey;
                }

                return LineTooltipItem(
                  '$type\n${DateFormat('dd/MM/yyyy').format(date)}\n${barSpot.y.toStringAsFixed(1)} صفحة',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
