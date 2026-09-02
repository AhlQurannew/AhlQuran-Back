import 'package:get/get.dart';
import 'profile_controller.dart';

class DrawerController extends GetxController {
  // Get reference to ProfileController
  final ProfileController profileController = Get.find<ProfileController>();

  final selectedIndex = 0.obs;

  void changeSelectedIndex(int index) {
    selectedIndex.value = index;
  }
}
