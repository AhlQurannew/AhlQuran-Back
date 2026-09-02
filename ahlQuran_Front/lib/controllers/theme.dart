import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ThemeController extends GetxController {
  Rx<ThemeMode> mode = ThemeMode.light.obs;
  switchTheme() => mode.value =
      mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}
