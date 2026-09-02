import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/drawer_controller.dart' as mydrawer;
import '../controllers/font_loader.dart';
import '../controllers/auth_controller.dart';

class StarterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FontController());

    Get.put(ProfileController());
    Get.put(mydrawer.DrawerController());
    Get.put(AuthController());
    //Get.put(() => ThemeController());
  }
}
