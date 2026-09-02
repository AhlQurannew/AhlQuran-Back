import 'package:get/get.dart';
import '../controllers/form_controller.dart' as form;
import '../controllers/subscription_information.dart';

class CopyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SubscriptionInformationController());
    Get.lazyPut(() => form.FormController(6), tag: "copyPage");
  }
}
