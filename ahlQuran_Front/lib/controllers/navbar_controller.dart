import 'package:get/get.dart';

class NavBarController extends GetxController {
  var isHovered = <bool>[].obs;

  void initHovered(int length) {
    if (isHovered.isEmpty) {
      isHovered.assignAll(List.generate(length, (index) => false));
    }
  }

  void setHovered(int index, bool value) {
    isHovered[index] = value;
  }
}
