import 'package:get/get.dart';
import '../system/widgets/attendance/attendance.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AttendanceController>(AttendanceController());
  }
}
