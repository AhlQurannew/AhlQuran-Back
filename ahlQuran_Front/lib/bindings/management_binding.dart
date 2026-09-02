import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/generic_controller.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class ManagementBinding<T extends Model> extends Bindings {
  final T Function(Map<String, dynamic> json) fromJson;

  ManagementBinding({required this.fromJson});

  @override
  void dependencies() {
    Get.lazyPut(() => GenericController<T>(fromJson: fromJson));
  }
}
