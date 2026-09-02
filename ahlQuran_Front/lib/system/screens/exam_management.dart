import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/grid_card_button_menu.dart';
import 'base_layout.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  OverlayEntry? overlayEntry;
  RxnInt id = RxnInt();

  @override
  void initState() {
    super.initState();
  }

  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: BaseLayout(
            title: "Exam Management",
            child: GridCardButtonMenu(children: [
              GridCardButton(
                title: "سجل الاختبارات",
                icon: Icons.list,
                onPressed: () {
                  Get.toNamed('/exams/records');
                },
              ),
              GridCardButton(
                title: "تقديرات الاختبارات",
                icon: Icons.list,
                onPressed: () {
                  Get.toNamed('/exams/notes');
                },
              ),
              GridCardButton(
                title: "ادارة لجنة الاختبارات",
                icon: Icons.list,
                onPressed: () {
                  Get.toNamed('/exams/teachers');
                },
              ),
              GridCardButton(
                title: "انواع الاختبارات",
                icon: Icons.list,
                onPressed: () {
                  Get.toNamed('/exams/types');
                },
              ),
            ])));
  }
}
