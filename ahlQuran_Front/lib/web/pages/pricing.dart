import 'package:flutter/material.dart';

import '../../system/widgets/footer.dart';
import '../widgets/custom_app_section.dart';
import '../widgets/page_header.dart';
import '../widgets/pricing_content.dart';
import '../widgets/pricing_section.dart';
import '../widgets/additional_services_section.dart';
import 'baselayout.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  _PricingPageState createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final ScrollController _scrollController = ScrollController();

  bool showNavbarBackground = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && !showNavbarBackground) {
      setState(() => showNavbarBackground = true);
    } else if (_scrollController.offset <= 100 && showNavbarBackground) {
      setState(() => showNavbarBackground = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const BaseLayout(
      stackedChild: PageHeader(
        title: 'الأسعار',
        subtitle: 'الأسعار/الرئيسية',
      ),
      bodyChild: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50),
          PricingContent(),
          PricingSection(),
          AdditionalServicesSection(),
          CustomAppPricingSection(),
          FooterSection(),
        ],
      ),
    );
  }
}
