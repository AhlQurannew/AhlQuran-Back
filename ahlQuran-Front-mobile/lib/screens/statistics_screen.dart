import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/guardian.dart';
import '../models/student.dart';
import '../services/guardian_service.dart';
import '../widgets/app_background.dart';
import 'profile_screen.dart';
import 'child_selection_screen.dart';
import 'attendance_ward_selection_screen.dart';
import 'achievements_ward_selection_screen.dart';
import 'statistics_ward_selection_screen.dart';

class StatisticsScreen extends StatefulWidget {
  final LoginResponse loginResponse;
  final Student student;

  const StatisticsScreen({
    super.key,
    required this.loginResponse,
    required this.student,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final GuardianService _guardianService = GuardianService();
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();

  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _excusedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  String get _selectedMonth {
    return DateFormat('MMMM yyyy').format(_selectedDate);
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate start and end dates for the selected month
      final firstDayOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      );

      final startDate = DateFormat('dd-MM-yyyy').format(firstDayOfMonth);
      final endDate = DateFormat('dd-MM-yyyy').format(lastDayOfMonth);

      final response = await _guardianService.getStudentAttendance(
        studentId: widget.student.id,
        startDate: startDate,
        endDate: endDate,
        page: 1,
        pageSize: 100,
      );

      // Filter records to only include those from the selected month
      final filteredRecords = response.items.where((record) {
        try {
          final dateParts = record.date.split('-');
          final recordMonth = int.parse(dateParts[1]);
          final recordYear = int.parse(dateParts[2]);

          return recordYear == _selectedDate.year &&
              recordMonth == _selectedDate.month;
        } catch (e) {
          return false;
        }
      }).toList();

      // Count attendance types
      int present = 0;
      int absent = 0;
      int late = 0;
      int excused = 0;

      for (var record in filteredRecords) {
        switch (record.status.toLowerCase()) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
          case 'excused':
            excused++;
            break;
        }
      }

      setState(() {
        _presentCount = present;
        _absentCount = absent;
        _lateCount = late;
        _excusedCount = excused;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    _loadStatistics();
  }

  void _nextMonth() {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1);
    final now = DateTime.now();

    // Don't allow navigation to future months
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }

    setState(() {
      _selectedDate = nextMonth;
    });
    _loadStatistics();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month;
  }

  void _showMonthPicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6200),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadStatistics();
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

                  // Top card with Statistics icon and logo
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
                                      Icons.bar_chart,
                                      color: Color(0xFFFF6200),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Statistics',
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

                  // Month selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 20,
                                ),
                                onPressed: _previousMonth,
                                color: const Color(0xFFFF6200),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _showMonthPicker,
                                child: Text(
                                  _selectedMonth,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                    height: 1.4,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                  color: _isCurrentMonth
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFFFF6200),
                                ),
                                onPressed: _isCurrentMonth ? null : _nextMonth,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Statistics cards
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
                                    onPressed: _loadStatistics,
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
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Present',
                                        'حاضر',
                                        _presentCount,
                                        const Color(0xFF41D7AC),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Absent',
                                        'غائب',
                                        _absentCount,
                                        const Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Late',
                                        'متأخر',
                                        _lateCount,
                                        const Color(0xFFFFA500),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Excused',
                                        'معذور',
                                        _excusedCount,
                                        const Color(0xFF4A90E2),
                                      ),
                                    ),
                                  ],
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

  Widget _buildStatCard(String title, String titleAr, int count, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titleAr,
                style: const TextStyle(
                  fontFamily: 'AbdoMisr',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: Color(0xFF6C7278),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
