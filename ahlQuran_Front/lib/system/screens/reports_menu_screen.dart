import 'package:flutter/material.dart';
import 'base_layout.dart';
import 'package:get/get.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dashboardtile.dart';

class ReportsMenuScreen extends StatefulWidget {
  const ReportsMenuScreen({super.key});

  @override
  State<ReportsMenuScreen> createState() => _ReportsMenuScreenState();
}

class _ReportsMenuScreenState extends State<ReportsMenuScreen> {
  @override
  void initState() {
    super.initState();

    // Set sidebar selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<drawer.DrawerController>()) {
          Get.find<drawer.DrawerController>().changeSelectedIndex(11);
        }
      } catch (e) {
        // Ignore error if controller not found
      }
    });
  }

  List<DashboardTileConfig> _getReportTiles() {
    return [
      DashboardTileConfig(
        label: 'تقرير الإنجاز اليومي',
        icon: Icons.description,
        bigIcon: Icons.description_outlined,
        route: '/daily-achievement-report-selection',
      ),
      DashboardTileConfig(
        label: 'تقرير المواظبة',
        icon: Icons.description,
        bigIcon: Icons.description_outlined,
        route: '/attendance-report-selection',
      ),
      DashboardTileConfig(
        label: 'التقرير التفصيلي للطالب',
        icon: Icons.description,
        bigIcon: Icons.description_outlined,
        route: '/student-detail-report-selection',
      ),
      DashboardTileConfig(
        label: 'التقرير التفصيلي للحلقات',
        icon: Icons.description,
        bigIcon: Icons.description_outlined,
        route: '/lecture-detail-report-selection',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'التقارير',
      child: Column(
        children: [
          // Golden header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDEB059),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'الصفحة الرئيسية / التقارير',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Centered 2x2 grid
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: _getReportTiles().length,
                  itemBuilder: (context, index) {
                    final reportTiles = _getReportTiles();
                    // Apply mint green background to all report tiles
                    final config = DashboardTileConfig(
                      label: reportTiles[index].label,
                      icon: reportTiles[index].icon,
                      bigIcon: reportTiles[index].bigIcon,
                      page: reportTiles[index].page,
                      route: reportTiles[index].route,
                      count: reportTiles[index].count,
                      isWide: reportTiles[index].isWide,
                      backgroundColor: const Color(0xFF4DB6AC),
                    );

                    return DashboardTile(config: config);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
