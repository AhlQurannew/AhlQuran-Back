import 'package:get/get.dart';
import '../../controllers/charts/chart_filter_controller.dart';

class Stat1Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartFilterController>(
      () => ChartFilterController(tag: 'stat1'),
      tag: 'stat1',
    );
  }
}
