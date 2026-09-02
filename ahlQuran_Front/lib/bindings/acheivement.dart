import 'package:get/get.dart';
import '../controllers/achievement.dart';

class AcheivementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AchievementController());
  }
}
