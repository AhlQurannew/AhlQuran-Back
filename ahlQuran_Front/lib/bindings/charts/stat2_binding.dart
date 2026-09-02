import 'package:get/get.dart';
import '../../controllers/charts/chart_filter_controller.dart';

class Stat2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartFilterController>(
      () => ChartFilterController(tag: 'stat2'),
      tag: 'stat2',
    );
  }
}
