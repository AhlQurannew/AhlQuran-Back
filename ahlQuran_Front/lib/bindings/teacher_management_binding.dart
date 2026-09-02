import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/screens/teacher_management_new.dart';

class TeacherManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherManagementController>(
      () => TeacherManagementController(),
    );
  }
}
