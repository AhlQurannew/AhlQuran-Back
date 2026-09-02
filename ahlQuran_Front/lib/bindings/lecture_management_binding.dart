import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/lecture_management_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_edit_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/lecture_form.dart';

class LectureManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LectureManagementController>(
        () => LectureManagementController());
    Get.lazyPut<GenericController<LectureForm>>(
        () => GenericController<LectureForm>(fromJson: LectureForm.fromJson));
    Get.lazyPut<GenericEditController<LectureForm>>(() =>
        GenericEditController<LectureForm>(initialmodel: null, isEdit: false));
  }
}
