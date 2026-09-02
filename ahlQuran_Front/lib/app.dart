import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'controllers/theme.dart';
import 'system/utils/theme.dart';
import 'routes/app_screens.dart';
import 'bindings/starter.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeController.mode.value,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          initialBinding: StarterBinding(),
          getPages: AppScreens.routes,
          locale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          // Don't set home or initialRoute - let GetX handle routing based on current URL
          // This allows deep linking and page refresh to work properly
        ));
  }
}
