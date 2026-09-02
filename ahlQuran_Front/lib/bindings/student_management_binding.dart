import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/student_management_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/student.dart';

class StudentManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentManagementController>(
        () => StudentManagementController());
    Get.lazyPut<GenericController<Student>>(
        () => GenericController<Student>(fromJson: Student.fromJson));
    Get.lazyPut<GenericEditController<Student>>(() =>
        GenericEditController<Student>(initialmodel: null, isEdit: false));
  }
}
