import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/guardian.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/guardian_service.dart';
import '../widgets/app_background.dart';
import 'profile_screen.dart';
import 'child_selection_screen.dart';
import 'statistics_ward_selection_screen.dart';
import 'achievements_ward_selection_screen.dart';
import 'attendance_ward_selection_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final LoginResponse loginResponse;
  final Student student;

  const AttendanceScreen({
    super.key,
    required this.loginResponse,
    required this.student,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GuardianService _guardianService = GuardianService();
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String get _selectedMonth {
    return DateFormat('MMMM yyyy').format(_selectedDate);
  }

  Future<void> _loadAttendance() async {
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

      // Debug: Print the dates being requested
      print('Loading attendance for: $startDate to $endDate');
      print('Selected date: ${_selectedDate.year}-${_selectedDate.month}');

      final response = await _guardianService.getStudentAttendance(
        studentId: widget.student.id,
        startDate: startDate,
        endDate: endDate,
        page: _currentPage,
        pageSize: 50,
      );

      print('Received ${response.items.length} attendance records');

      // Filter records to only include those from the selected month
      final filteredRecords = response.items.where((record) {
        try {
          final dateParts = record.date.split('-');
          final recordMonth = int.parse(dateParts[1]);
          final recordYear = int.parse(dateParts[2]);

          return recordYear == _selectedDate.year &&
              recordMonth == _selectedDate.month;
        } catch (e) {
          print('Error parsing date: ${record.date}');
          return false;
        }
      }).toList();

      print(
        'Filtered to ${filteredRecords.length} records for ${_selectedDate.month}/${_selectedDate.year}',
      );

      setState(() {
        _attendanceRecords = filteredRecords;
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
      _currentPage = 1;
    });
    _loadAttendance();
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
      _currentPage = 1;
    });
    _loadAttendance();
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
      lastDate: now, // Restrict to current date
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
        _currentPage = 1;
      });
      _loadAttendance();
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

                  // Top card with My Attendance icon and logo
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
                                      Icons.check_circle,
                                      color: Color(0xFFFF6200),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'My Attendance',
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

                  // Attendance Info Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance Info',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                    height: 1.4,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Month selector with arrows
                                Row(
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
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showMonthPicker,
                                      child: Text(
                                        _selectedMonth,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 20,
                                          height: 1.4,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 20,
                                        color: _isCurrentMonth
                                            ? const Color(0xFFCCCCCC)
                                            : const Color(0xFFFF6200),
                                      ),
                                      onPressed: _isCurrentMonth
                                          ? null
                                          : _nextMonth,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Attendance list
                                Expanded(
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFF6200),
                                          ),
                                        )
                                      : _errorMessage != null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                onPressed: _loadAttendance,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFFF6200,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _attendanceRecords.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No attendance records for this month',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Color(0xFF6C7278),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _attendanceRecords.length,
                                          itemBuilder: (context, index) {
                                            final record =
                                                _attendanceRecords[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: _buildAttendanceRow(
                                                record,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildAttendanceRow(AttendanceRecord record) {
    // Parse the date from DD-MM-YYYY format
    final dateParts = record.date.split('-');
    final day = dateParts[0];
    final monthNum = int.parse(dateParts[1]);
    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final displayDate = '$day ${monthNames[monthNum]}';

    Color statusColor;
    switch (record.status.toLowerCase()) {
      case 'present':
        statusColor = const Color(0xFF41D7AC);
        break;
      case 'late':
        statusColor = const Color(0xFFFFA500);
        break;
      case 'excused':
        statusColor = const Color(0xFF4A90E2);
        break;
      case 'absent':
      default:
        statusColor = const Color(0xFFFF6B6B);
        break;
    }

    return Row(
      children: [
        Text(
          displayDate,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            height: 1.5,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            record.statusArabic,
            style: const TextStyle(
              fontFamily: 'AbdoMisr',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
