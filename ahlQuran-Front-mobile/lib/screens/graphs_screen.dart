import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/guardian.dart';
import '../models/student.dart';
import '../services/guardian_service.dart';
import '../widgets/app_background.dart';
import '../data/quran_page_data.dart';
import 'profile_screen.dart';
import 'child_selection_screen.dart';
import 'attendance_ward_selection_screen.dart';
import 'statistics_ward_selection_screen.dart';
import 'achievements_ward_selection_screen.dart';

class GraphsScreen extends StatefulWidget {
  final LoginResponse loginResponse;
  final Student student;

  const GraphsScreen({
    super.key,
    required this.loginResponse,
    required this.student,
  });

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  final GuardianService _guardianService = GuardianService();
  bool _isLoading = true;
  String? _errorMessage;

  List<FlSpot> _memorizedData = [];
  List<FlSpot> _minorRevisionData = [];
  List<FlSpot> _majorRevisionData = [];
  List<String> _dateLabels = [];

  @override
  void initState() {
    super.initState();
    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch achievements for the student
      final response = await _guardianService.getStudentAchievements(
        studentId: widget.student.id,
        page: 1,
        pageSize: 100,
      );

      // Group achievements by date and calculate pages
      final Map<String, Map<String, int>> dateData = {};

      for (var achievement in response.items) {
        final date = achievement.date;
        if (!dateData.containsKey(date)) {
          dateData[date] = {'memorized': 0, 'minor': 0, 'major': 0};
        }

        // Calculate pages using accurate Quran page data
        final startPage = QuranPageData.getPageNumber(
          achievement.fromSurah,
          achievement.fromVerse,
        );
        final endPage = QuranPageData.getPageNumber(
          achievement.toSurah,
          achievement.toVerse,
        );
        final pages = (startPage != null && endPage != null)
            ? (endPage - startPage + 1)
            : 0;

        switch (achievement.achievementType.toLowerCase()) {
          case 'normal':
            dateData[date]!['memorized'] =
                (dateData[date]!['memorized'] ?? 0) + pages;
            break;
          case 'small':
            dateData[date]!['minor'] = (dateData[date]!['minor'] ?? 0) + pages;
            break;
          case 'big':
            dateData[date]!['major'] = (dateData[date]!['major'] ?? 0) + pages;
            break;
        }
      }

      // Sort dates and create chart data
      final sortedDates = dateData.keys.toList()
        ..sort((a, b) {
          final dateA = DateFormat('dd-MM-yyyy').parse(a);
          final dateB = DateFormat('dd-MM-yyyy').parse(b);
          return dateA.compareTo(dateB);
        });

      final List<FlSpot> memorized = [];
      final List<FlSpot> minor = [];
      final List<FlSpot> major = [];
      final List<String> labels = [];

      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final data = dateData[date]!;

        memorized.add(FlSpot(i.toDouble(), data['memorized']!.toDouble()));
        minor.add(FlSpot(i.toDouble(), data['minor']!.toDouble()));
        major.add(FlSpot(i.toDouble(), data['major']!.toDouble()));

        // Format date for label (e.g., "16 Feb")
        final parsedDate = DateFormat('dd-MM-yyyy').parse(date);
        labels.add(DateFormat('d MMM').format(parsedDate));
      }

      setState(() {
        _memorizedData = memorized;
        _minorRevisionData = minor;
        _majorRevisionData = major;
        _dateLabels = labels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Top card with Graphs icon and logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: 80,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF6200,
                                      ).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.show_chart,
                                      color: Color(0xFFFF6200),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Progress Graph',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      height: 1.4,
                                      letterSpacing: -0.01,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                'assets/landing/logo-landing.svg',
                                width: 58,
                                height: 39.13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Graph content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6200),
                            ),
                          )
                        : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Color(0xFFFF6200),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadGraphData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6200),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _memorizedData.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF6C7278),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              children: [
                                // Legend
                                _buildLegend(),
                                const SizedBox(height: 16),

                                // Chart
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      height: 300,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: _buildChart(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 104,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  loginResponse: widget.loginResponse,
                                ),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.person_outline, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChildSelectionScreen(
                                  loginResponse: widget.loginResponse,
                                ),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.people_outline, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AttendanceWardSelectionScreen(
                                      loginResponse: widget.loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(
                            Icons.check_circle_outline,
                            false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StatisticsWardSelectionScreen(
                                      loginResponse: widget.loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(Icons.bar_chart_outlined, false),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AchievementsWardSelectionScreen(
                                      loginResponse: widget.loginResponse,
                                    ),
                              ),
                            );
                          },
                          child: _buildNavItem(
                            Icons.psychology_outlined,
                            false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Memorized', const Color(0xFF41D7AC)),
              _buildLegendItem('Minor Rev.', const Color(0xFF4A90E2)),
              _buildLegendItem('Major Rev.', const Color(0xFFFF6B6B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getYAxisInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _dateLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dateLabels[index],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: Color(0xFF6C7278),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getYAxisInterval(),
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Color(0xFF6C7278),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        minX: 0,
        maxX: (_dateLabels.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          // Memorized line
          if (_memorizedData.isNotEmpty)
            LineChartBarData(
              spots: _memorizedData,
              isCurved: true,
              color: const Color(0xFF41D7AC),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          // Minor revision line
          if (_minorRevisionData.isNotEmpty)
            LineChartBarData(
              spots: _minorRevisionData,
              isCurved: true,
              color: const Color(0xFF4A90E2),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          // Major revision line
          if (_majorRevisionData.isNotEmpty)
            LineChartBarData(
              spots: _majorRevisionData,
              isCurved: true,
              color: const Color(0xFFFF6B6B),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var spot in _memorizedData) {
      if (spot.y > max) max = spot.y;
    }
    for (var spot in _minorRevisionData) {
      if (spot.y > max) max = spot.y;
    }
    for (var spot in _majorRevisionData) {
      if (spot.y > max) max = spot.y;
    }
    // Add 20% padding and round up to nearest 5
    final maxWithPadding = max * 1.2;
    return (maxWithPadding / 5).ceil() * 5.0;
  }

  double _getYAxisInterval() {
    final maxY = _getMaxY();
    // Show approximately 5-8 labels on Y axis
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 50;
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF6200).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? const Color(0xFFFF6200) : const Color(0xFF6C7278),
      ),
    );
  }
}
