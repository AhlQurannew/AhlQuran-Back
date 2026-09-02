import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/login.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/image.dart';

//TODO use load asset widget to load images
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: IntroductionScreen(
        globalBackgroundColor: colorScheme.surface,
        showSkipButton: true,
        showNextButton: true,
        next: const Icon(Icons.arrow_forward, size: 24),
        skip: Text(
          "تخطي",
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        ),
        done: Text(
          "تخطي",
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        ),
        onDone: () => _navigateToLogin(context),
        onSkip: () => _navigateToLogin(context),
        dotsDecorator: DotsDecorator(
          activeColor: colorScheme.primary,
          size: const Size(10, 10),
          activeSize: const Size(22, 10),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        pages: [
          PageViewModel(
            titleWidget: Text(
              "أهل القرآن",
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            bodyWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "تسهيل و تسبب التعليم القرائي",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  "نظام أهل القرآن هو نظام سحابي متكامل بهدف لتوظيف آخر ما توصلت إليه التقنية في خدمة تعليم القرآن الكريم",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            image: Padding(
              padding: const EdgeInsets.only(top: 40),
              child:
                  CustomAssetImage(assetPath: "assets/logo.png", height: 150),
            ),
            decoration: const PageDecoration(
              bodyPadding: EdgeInsets.symmetric(horizontal: 24),
              imagePadding: EdgeInsets.zero,
            ),
          ),
          PageViewModel(
            titleWidget: Text(
              "تطوير وبرمجة",
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            bodyWidget: Text(
              "شركة  للبرمجة المتخصصة في تصميم وتطوير المواقع الإلكترونية والتطبيقات الذكية.",
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            image: Padding(
              padding: const EdgeInsets.only(top: 40),
              child:
                  CustomAssetImage(assetPath: "assets/logo2.png", height: 150),
            ),
            decoration: const PageDecoration(
              bodyPadding: EdgeInsets.symmetric(horizontal: 24),
              imagePadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LogIn()),
    );
  }
}
