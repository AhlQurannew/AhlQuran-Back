import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:get/get.dart';

import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dashboardtile.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/header.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';
import './base_layout.dart';

import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/track_and_memorize_screen.dart';

import 'package:the_doctarine_of_the_ppl_of_the_quran/routes/app_routes.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/api_client.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/teacher.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/lecture.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/guardian.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int studentsCount = 0;
  int teachersCount = 0;
  int lecturesCount = 0;
  int guardiansCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      // Get user role from ProfileController
      final profileController = Get.find<ProfileController>();
      final userRole = profileController.userRole.value.toLowerCase();
      
      dev.log('Dashboard: Loading counts for role: $userRole');
      
      // Determine which student endpoint to use based on role
      final studentEndpoint = userRole == 'teacher' 
          ? ApiEndpoints.getMyStudents 
          : ApiEndpoints.getStudents;
      
      dev.log('Dashboard: Using student endpoint: $studentEndpoint');

      // Teachers have limited access - only fetch what they can access
      if (userRole == 'teacher') {
        try {
          final results = await Future.wait([
            ApiService.fetchList(studentEndpoint, Student.fromJson),
            ApiService.fetchList(ApiEndpoints.getMyLectures, Lecture.fromJson),
          ]);
          
          dev.log('Dashboard: Fetched ${results[0].length} students');
          dev.log('Dashboard: Fetched ${results[1].length} lectures');
          
          setState(() {
            studentsCount = results[0].length;
            teachersCount = 0; // Teachers can't see other teachers
            lecturesCount = results[1].length;
            guardiansCount = 0; // Teachers can't see guardians
            isLoading = false;
          });
        } catch (e) {
          dev.log('Error loading teacher dashboard counts: $e');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // Admin/President/Supervisor - fetch all counts in parallel
        final results = await Future.wait([
          ApiService.fetchList(studentEndpoint, Student.fromJson),
          ApiService.fetchList(ApiEndpoints.getTeachers, Teacher.fromJson),
          ApiService.fetchList(ApiEndpoints.getLectures, Lecture.fromJson),
          ApiService.fetchList(ApiEndpoints.getGuardians, Guardian.fromJson),
        ]);

        dev.log('Dashboard: Fetched ${results[0].length} students');

        setState(() {
          studentsCount = results[0].length;
          teachersCount = results[1].length;
          lecturesCount = results[2].length;
          guardiansCount = results[3].length;
          isLoading = false;
        });
      }
    } catch (e) {
      dev.log('Error loading dashboard counts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DashboardTileConfig> _getTiles() {
    // Get user role from ProfileController
    final profileController = Get.find<ProfileController>();
    final userRole = profileController.userRole.value.toLowerCase();

    // Check if user is president or admin
    final canManageSupervisors = userRole == 'president' || userRole == 'admin';
    final isTeacher = userRole == 'teacher';

    final allTiles = [
      DashboardTileConfig(
        label: 'الطلاب',
        count: studentsCount.toString(),
        icon: Icons.people,
        bigIcon: Icons.people,
        route: Routes.addStudent,
      ),
      // Hide teachers tile for teachers
      if (!isTeacher)
        DashboardTileConfig(
          label: 'المعلمين',
          count: teachersCount.toString(),
          icon: Icons.people_outline,
          bigIcon: Icons.people_outline,
          route: Routes.addTeacher,
        ),
      DashboardTileConfig(
        label: 'الحلقات',
        count: lecturesCount.toString(),
        icon: Icons.list,
        bigIcon: Icons.list_alt,
        route: Routes.addLecture,
      ),
      // Hide guardians tile for teachers
      if (!isTeacher)
        DashboardTileConfig(
          label: 'أولياء الأمور',
          count: guardiansCount.toString(),
          icon: Icons.person,
          bigIcon: Icons.person,
          route: Routes.addGuardian,
        ),
      DashboardTileConfig(
        label: 'حضور الطلاب',
        icon: Icons.event_available,
        bigIcon: Icons.event_available,
        route: Routes.attendance,
      ),
      // Hide teacher attendance tile for teachers
      if (!isTeacher)
        DashboardTileConfig(
          label: 'حضور المعلمين',
          icon: Icons.event,
          bigIcon: Icons.event,
          route: Routes.teacherAttendance,
        ),
      // Only show supervisor management for presidents and admins
      if (canManageSupervisors)
        DashboardTileConfig(
          label: 'تسيير المشرفين',
          icon: Icons.event_note,
          bigIcon: Icons.event_note,
          route: Routes.supervisorManagement,
        ),
      DashboardTileConfig(
        label: 'الحفظ والمراجعة',
        icon: Icons.check_box,
        bigIcon: Icons.check_box_outlined,
        page: () => const TrackAndMemorizeScreen(),
      ),
      // Hide reports and statistics for teachers
      if (!isTeacher)
        DashboardTileConfig(
          label: 'التقارير',
          icon: Icons.description,
          bigIcon: Icons.description_outlined,
          route: Routes.reportsMenu,
        ),
      if (!isTeacher)
        DashboardTileConfig(
          label: 'الإحصاءات',
          icon: Icons.bar_chart,
          bigIcon: Icons.bar_chart_outlined,
          route: Routes.chartsMenu,
        ),
      DashboardTileConfig(
        label: 'الامتحانات (قريباً)',
        icon: Icons.check_circle,
        bigIcon: Icons.check_circle_outline,
        page: () => const SizedBox.shrink(), // Placeholder
      ),
    ];

    return allTiles;
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'لوحة التحكم',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 16;
                const int maxColumns = 4;
                const int maxRows = 3;

                // Calculate number of columns based on available width
                // but cap at maxColumns (4)
                int crossAxisCount = maxColumns;
                if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                }
                if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                }
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                }

                // Limit items to maxRows * maxColumns
                const maxItems = maxRows * maxColumns;
                final tiles = _getTiles();
                final displayedTiles = tiles.take(maxItems).toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Header(),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 3.5,
                        ),
                        itemCount: displayedTiles.length,
                        itemBuilder: (context, index) {
                          // Calculate which row this item is in (0-indexed)
                          final row = index ~/ crossAxisCount;
                          // Apply mint green background to 2nd row (row index 1)
                          final backgroundColor =
                              row == 1 ? const Color(0xFF4DB6AC) : null;

                          // Create a modified config with the background color
                          final config = DashboardTileConfig(
                            label: displayedTiles[index].label,
                            icon: displayedTiles[index].icon,
                            bigIcon: displayedTiles[index].bigIcon,
                            page: displayedTiles[index].page,
                            route: displayedTiles[index].route,
                            count: displayedTiles[index].count,
                            isWide: displayedTiles[index].isWide,
                            backgroundColor: backgroundColor,
                          );

                          return DashboardTile(config: config);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
