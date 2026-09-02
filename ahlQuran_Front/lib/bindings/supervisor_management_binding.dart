import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/supervisor_management_new.dart';

class SupervisorManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupervisorManagementController>(
        () => SupervisorManagementController());
  }
}
