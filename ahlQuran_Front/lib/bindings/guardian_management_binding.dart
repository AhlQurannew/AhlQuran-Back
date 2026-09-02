import 'package:get/get.dart';
import '../system/screens/guardian_management_new.dart';

class GuardianManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuardianManagementController>(
      () => GuardianManagementController(),
    );
  }
}
