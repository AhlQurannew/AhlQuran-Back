import 'package:get/get.dart';
import '../controllers/charts/chart_config_controller.dart';

class ChartConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartConfigController>(() => ChartConfigController());
  }
}
