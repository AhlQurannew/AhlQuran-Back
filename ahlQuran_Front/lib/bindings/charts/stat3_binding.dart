import 'package:get/get.dart';
import '../../controllers/charts/chart_filter_controller.dart';

class Stat3Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChartFilterController>(
      () => ChartFilterController(tag: 'stat3'),
      tag: 'stat3',
    );
  }
}
