import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/form_controller.dart' as form;
import '../../system/widgets/footer.dart';
import '../../controllers/subscription_information.dart';
import '../widgets/form.dart';
import './baselayout.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/image.dart';
import '../widgets/page_header.dart';

class CopyPage extends StatefulWidget {
  const CopyPage({super.key});

  @override
  State<CopyPage> createState() => _CopyPageState();
}

class _CopyPageState extends State<CopyPage> {
  final _formKey = GlobalKey<FormState>();
  final form.FormController _formController =
      Get.find<form.FormController>(tag: "copyPage");

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BaseLayout(
      stackedChild: PageHeader(
        title: 'الأسعار',
        subtitle: 'الأسعار/الرئيسية',
      ),
      bodyChild: Column(
        children: [
          LearnMoreSection(screenSize: screenSize),
          const SizedBox(height: 20),
          FormAndSubscriptionSection(
            formKey: _formKey,
            formController: _formController,
          ),
          const SizedBox(height: 80),
          const FooterSection(),
        ],
      ),
    );
  }
}

class LearnMoreSection extends StatelessWidget {
  final Size screenSize;

  const LearnMoreSection({super.key, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenSize.height * 0.2,
      width: screenSize.width * 0.9,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InfoLinksWithImages(text: 'تريد التعرف على النظام أكثر ؟'),
          InfoLinksWithImages(text: 'تريد التعرف على العروض والأسعار ؟'),
        ],
      ),
    );
  }
}

class FormAndSubscriptionSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final form.FormController formController;

  const FormAndSubscriptionSection({
    super.key,
    required this.formKey,
    required this.formController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1000;

        final subscription = SubscriptionInformation(
          onEmptyFeild: () => formController.moveToFirstEmptyField(formKey),
          subscriptionFormKey: formKey,
        );

        final formWidget = CustomFormWidget(formKey: formKey);

        return isMobile
            ? Column(
                children: [
                  subscription,
                  const SizedBox(height: 20),
                  formWidget,
                ],
              )
            : Row(
                children: [
                  Expanded(child: subscription),
                  Expanded(child: formWidget),
                ],
              );
      },
    );
  }
}

class InfoLinksWithImages extends StatefulWidget {
  final String text;

  const InfoLinksWithImages({super.key, required this.text});

  @override
  State<InfoLinksWithImages> createState() => _InfoLinksWithImagesState();
}

class _InfoLinksWithImagesState extends State<InfoLinksWithImages> {
  Color hoverColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.right,
        text: TextSpan(
          children: [
            WidgetSpan(child: CustomAssetImage(assetPath: 'page.png')),
            TextSpan(text: widget.text),
            TextSpan(
              text: ' اضغط هنا',
              style: TextStyle(color: hoverColor),
              onEnter: (_) => setState(() => hoverColor = Colors.yellow),
              onExit: (_) => setState(() => hoverColor = Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Add navigation path
                },
            ),
          ],
        ),
      ),
    );
  }
}
