import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/dashboardtile.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import 'base_layout.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BaseLayout(
        title: "لوحة تحكم المعلم",
        child: Column(
          children: [
            // Welcome header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4DB6AC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً ${profileController.firstName.value} ${profileController.lastName.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'معلم',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )),
            ),
            const SizedBox(height: 32),

            // Dashboard tiles
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  DashboardTile(
                    config: DashboardTileConfig(
                      label: 'طلابي',
                      icon: Icons.people,
                      bigIcon: Icons.people_outlined,
                      route: Routes.addStudent,
                      backgroundColor: const Color(0xFF4DB6AC),
                    ),
                  ),
                  DashboardTile(
                    config: DashboardTileConfig(
                      label: 'الحفظ والمراجعة',
                      icon: Icons.check_box,
                      bigIcon: Icons.check_box_outlined,
                      route: Routes.trackAndMemorize,
                      backgroundColor: const Color(0xFF4DB6AC),
                    ),
                  ),
                  DashboardTile(
                    config: DashboardTileConfig(
                      label: 'حضور الطلاب',
                      icon: Icons.event_available,
                      bigIcon: Icons.event_available_outlined,
                      route: Routes.attendance,
                      backgroundColor: const Color(0xFF4DB6AC),
                    ),
                  ),
                  DashboardTile(
                    config: DashboardTileConfig(
                      label: 'التقارير',
                      icon: Icons.description,
                      bigIcon: Icons.description_outlined,
                      route: Routes.reportsMenu,
                      backgroundColor: const Color(0xFF4DB6AC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
