import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/date_picker.dart';
import 'base_layout.dart';
import '../widgets/typehead.dart';
import '../widgets/grids/acheivement/acheivement_show.dart';
import '../../controllers/achievement.dart';
//import 'dart:developer' as dev;

class AddAcheivement extends StatefulWidget {
  const AddAcheivement({super.key});

  @override
  State<AddAcheivement> createState() => _AddAcheivementState();
}

class _AddAcheivementState extends State<AddAcheivement> {
  RxnInt id = RxnInt();
  TextEditingController controller = TextEditingController();
  DateTime? selectedDate;
  late AchievementController achievementController;

  @override
  void initState() {
    super.initState();
    achievementController = Get.find<AchievementController>();
    final now = DateTime.now();
    controller.text = formatDate(now);
    achievementController.setDate(formatDate(now));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        final formattedDate = formatDate(picked);
        controller.text = formattedDate;
        achievementController.setDate(formattedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: BaseLayout(
        title: "Achievement Management",
        child: Column(children: [
          Row(
            children: [
              Expanded(
                child: SearchFeild(
                  selectedSession: (p0) {
                    setState(() {
                      id.value = p0;
                      achievementController.setLectureId(p0);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today,
                        color: theme.iconTheme.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: AcheivementScreen(
              id: id,
              date: controller.text,
            ),
          ),
        ]),
      ),
    );
  }
}
