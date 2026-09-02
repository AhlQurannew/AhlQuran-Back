import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'controllers/theme.dart';

// init
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  dev.log('Environment variables loaded: ${dotenv.env}');

  await initializeDateFormatting('ar');

  Get.put(ThemeController());

  runApp(const MyApp());
}
