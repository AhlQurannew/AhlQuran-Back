import 'package:flutter/material.dart';
import 'acheivement.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/achievement.dart';
import '../../error_illustration.dart';
import 'dart:developer' as dev;
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/three_bounce.dart';

class AcheivementScreen extends StatefulWidget {
  final RxnInt id;
  final String date;

  const AcheivementScreen({super.key, required this.id, required this.date});

  @override
  State<AcheivementScreen> createState() => _AcheivementScreenState();
}

class _AcheivementScreenState extends State<AcheivementScreen> {
  late AchievementController controller;
  Duration duration = const Duration(seconds: 5);
  bool minimumLoadTimeCompleted = false;

  void _loadData() {
    controller.isLoading.value = true;

    Future.wait([
      Future.delayed(duration),
    ]).then((_) {
      if (mounted) {
        controller.isLoading.value = false;
        controller.setLectureId(widget.id.value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<AchievementController>();
    dev.log("id in initState: ${widget.id.value}");
    ever(widget.id, (_) {
      dev.log("id in ever: ${widget.id.value}");
      controller.setLectureId(widget.id.value);
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show select lecture illustration when no lecture is selected
      if (controller.lectureId.value == null) {
        return ErrorIllustration(
          illustrationPath: 'assets/illustration/select.svg',
          title: 'Select a Lecture',
          message: 'Please select a lecture to view student achievements.',
        );
      }

      // Show loading indicator while fetching data
      if (controller.isLoading.value) {
        return Center(child: ThreeBounce());
      }

      // Show error illustration if there's a connection error
      if (controller.errorMessage.value.isNotEmpty) {
        return ErrorIllustration(
          illustrationPath: 'assets/illustration/bad-connection.svg',
          title: 'Connection Error',
          message: controller.errorMessage.value,
          onRetry: _loadData,
        );
      }

      // Show empty state illustration when no data is found
      if (controller.achievementList.isEmpty &&
          controller.isrequestCompleted.value) {
        return ErrorIllustration(
          illustrationPath: 'assets/illustration/empty-box.svg',
          title: 'No Achievements Found',
          message: 'There are no achievements recorded for this lecture yet.',
        );
      }

      // Show the achievement grid when data is available
      return AcheivementGrid(
        data: controller.achievementList.toList(),
        date: widget.date,
        sessionId: widget.id.value!,
        onRefresh: () {
          _loadData();
          return controller.fetchData();
        },
      );
    });
  }
}
