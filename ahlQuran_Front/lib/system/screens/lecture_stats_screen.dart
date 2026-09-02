import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:fl_chart/fl_chart.dart';
import '../new_models/student.dart';
import '../new_models/achievement.dart';
import '../services/network/api_endpoints.dart';
import '../services/api_client.dart';
import '../../data/quran_page_data.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'base_layout.dart';

class LectureStatsScreen extends StatefulWidget {
  const LectureStatsScreen({super.key});

  @override
  State<LectureStatsScreen> createState() => _LectureStatsScreenState();
}

class _LectureStatsScreenState extends State<LectureStatsScreen> {
  String? lectureName;
  int? lectureId;
  String? startDate;
  String? endDate;
  List<Student> students = [];
  Map<int, double> studentPages = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Get parameters from Get.parameters
    final parameters = Get.parameters;
    lectureName = parameters['lectureName'] ?? '';
    lectureId = int.tryParse(parameters['lectureId'] ?? '');
    startDate = parameters['startDate'] ?? '';
    endDate = parameters['endDate'] ?? '';

    dev.log('Lecture ID: $lectureId, Start: $startDate, End: $endDate');

    _loadStudentsAndAchievements();

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

  Future<void> _loadStudentsAndAchievements() async {
    if (lectureId == null) {
      dev.log('Lecture ID is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      dev.log('Loading students for lecture: $lectureId');

      // Load students for this lecture
      final studentsResponse = await ApiService.fetchList(
        '${ApiEndpoints.getStudents}?lecture_id=$lectureId',
        Student.fromJson,
      );

      dev.log('Loaded ${studentsResponse.length} students');

      // Load achievements for each student
      for (var student in studentsResponse) {
        final studentId = student.id;
        if (studentId == null) {
          dev.log('Student ID is null, skipping');
          continue;
        }

        dev.log('Loading achievements for student: $studentId');

        final achievementsResponse = await ApiService.fetchList(
          '${ApiEndpoints.getStudents}$studentId/achievements',
          Achievement.fromJson,
        );

        dev.log(
            'Loaded ${achievementsResponse.length} achievements for student $studentId');

        // Filter achievements by date range and type 'normal' (حفظ only)
        final filteredAchievements = achievementsResponse.where((achievement) {
          // Only include 'normal' type achievements
          if (achievement.achievementType != 'normal') return false;

          if (startDate == null || endDate == null) return true;

          try {
            final achDate = _parseDate(achievement.date);
            final start = _parseDate(startDate!);
            final end = _parseDate(endDate!);

            final isInRange =
                achDate.isAfter(start.subtract(const Duration(days: 1))) &&
                    achDate.isBefore(end.add(const Duration(days: 1)));

            if (!isInRange) {
              dev.log(
                  'Achievement date ${achievement.date} not in range $startDate to $endDate');
            }

            return isInRange;
          } catch (e) {
            dev.log('Error parsing date: $e');
            return false;
          }
        }).toList();

        dev.log(
            'Filtered to ${filteredAchievements.length} achievements for student $studentId');

        // Calculate total pages for this student
        double totalPages = 0;
        for (var achievement in filteredAchievements) {
          final pages = _calculatePages(achievement);
          dev.log(
              'Achievement: ${achievement.fromSurah}:${achievement.fromVerse} to ${achievement.toSurah}:${achievement.toVerse} = $pages pages');
          totalPages += pages;
        }

        dev.log('Total pages for student $studentId: $totalPages');
        studentPages[studentId] = totalPages;
      }

      dev.log('Final student pages map: $studentPages');

      setState(() {
        students = studentsResponse;
        isLoading = false;
      });
    } catch (e) {
      dev.log('Error loading data: $e');
      setState(() {
        students = [];
        isLoading = false;
      });
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
        title: "إحصائيات الحلقة",
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
            'إحصائيات الحلقة',
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
    dev.log(
        'Building chart section. Students: ${students.length}, StudentPages: ${studentPages.length}');

    if (students.isEmpty) {
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
            'لا يوجد طلاب في هذه الحلقة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Check if all students have 0 pages
    final hasAnyData = studentPages.values.any((pages) => pages > 0);
    if (!hasAnyData) {
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
            'لا توجد إنجازات في هذه الفترة',
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
            'عدد الصفحات المحفوظة لكل طالب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Get max pages for scaling
    final maxPages = studentPages.values.isEmpty
        ? 10.0
        : studentPages.values.reduce((a, b) => a > b ? a : b);
    final roundedMaxY = (maxPages / 5).ceil() * 5.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: roundedMaxY > 0 ? roundedMaxY : 10,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final student = students[groupIndex];
              final studentName = student.personalInfo.getFullArName();
              return BarTooltipItem(
                '$studentName\n${rod.toY.toStringAsFixed(1)} صفحة',
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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= students.length) {
                  return const SizedBox.shrink();
                }
                final studentName =
                    students[index].personalInfo.getFullArName();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
        barGroups: students.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final studentId = student.id;
          final pages =
              studentId != null ? (studentPages[studentId] ?? 0) : 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: pages.toDouble(),
                color: const Color(0xFF4DB6AC),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
