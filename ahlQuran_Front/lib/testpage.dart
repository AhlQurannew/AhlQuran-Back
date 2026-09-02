import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              onPressed: () => Get.toNamed(Routes.copy),
              child: const Text('Copy Page'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.logIn),
              child: const Text('Login Page'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.addStudent),
              child: const Text('Student Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.addGuardian),
              child: const Text('Guardian Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.addLecture),
              child: const Text('Lecture Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.addAchievement),
              child: const Text('Achievement Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.attendance),
              child: const Text('Attendance Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.examPage),
              child: const Text('Exam Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.report1),
              child: const Text('Report 1'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.report2),
              child: const Text('Report 2'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.report3),
              child: const Text('Report 3'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.report4),
              child: const Text('Report 4'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.stat1),
              child: const Text('Stat 1'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.stat2),
              child: const Text('Stat 2'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.stat3),
              child: const Text('Stat 3'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.card),
              child: const Text('Card'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.financialManagement),
              child: const Text('Financial Management'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.createAccount),
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.forgetPassword),
              child: const Text('Forget Password'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.onboarding),
              child: const Text('Onboarding'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.dashboardPage),
              child: const Text('dashboard'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(WebRoutes.home),
              child: const Text('home'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(WebRoutes.features),
              child: const Text('features'),
            ),
            TextButton(
              onPressed: () => Get.toNamed(WebRoutes.pricing),
              child: const Text('Pricing'),
            ),
          ],
        ),
      ),
    );
  }
}
