import 'package:flutter/material.dart';
import 'base_layout.dart';
import 'package:get/get.dart';
import '../../controllers/drawer_controller.dart' as drawer;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dashboardtile.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/routes/app_routes.dart';

class ChartsMenuScreen extends StatefulWidget {
  const ChartsMenuScreen({super.key});

  @override
  State<ChartsMenuScreen> createState() => _ChartsMenuScreenState();
}

class _ChartsMenuScreenState extends State<ChartsMenuScreen> {
  @override
  void initState() {
    super.initState();

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

  List<DashboardTileConfig> _getChartTiles() {
    return [
      DashboardTileConfig(
        label: 'إحصائيات الإنجاز',
        icon: Icons.bar_chart,
        bigIcon: Icons.bar_chart_outlined,
        route: Routes.achievementStatsSelection,
      ),
      DashboardTileConfig(
        label: 'إحصائيات المواظبة',
        icon: Icons.bar_chart,
        bigIcon: Icons.bar_chart_outlined,
        route: Routes.attendanceStatsSelection,
      ),
      DashboardTileConfig(
        label: 'منحنى تطور الإنجاز',
        icon: Icons.show_chart,
        bigIcon: Icons.show_chart_outlined,
        route: Routes.progressStatsSelection,
      ),
      DashboardTileConfig(
        label: 'إحصائيات الحلقة',
        icon: Icons.bar_chart,
        bigIcon: Icons.bar_chart_outlined,
        route: Routes.lectureStatsSelection,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'الإحصاءات',
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
                  'الصفحة الرئيسية / الإحصاءات',
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
                  itemCount: _getChartTiles().length,
                  itemBuilder: (context, index) {
                    final chartTiles = _getChartTiles();
                    // Apply mint green background to all chart tiles
                    final config = DashboardTileConfig(
                      label: chartTiles[index].label,
                      icon: chartTiles[index].icon,
                      bigIcon: chartTiles[index].bigIcon,
                      page: chartTiles[index].page,
                      route: chartTiles[index].route,
                      count: chartTiles[index].count,
                      isWide: chartTiles[index].isWide,
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
