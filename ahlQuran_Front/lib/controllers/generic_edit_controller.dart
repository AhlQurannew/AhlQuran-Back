import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/model.dart';

class GenericEditController<T extends Model> extends GetxController {
  final Rx<T?> model;

  bool isEdit = false;
  GenericEditController({required T? initialmodel, required this.isEdit})
      : model = initialmodel.obs;

  void updatemodel(T newmodel) {
    model.value = newmodel;
  }
}
