import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/profile_controller.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final mintGreen = const Color(0xFF4DB6AC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mintGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(() {
            final firstName = profileController.firstName.value;
            final lastName = profileController.lastName.value;
            final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
                ? '$firstName $lastName'.trim()
                : profileController.userName.value;

            return Text(
              'مرحباً بك، $displayName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            );
          }),
          const SizedBox(height: 8),
          Text(
            'مرحبا بك في المنصة، يسر الله لك القيام بمهمتك السامية.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
