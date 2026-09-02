import 'package:flutter/material.dart';
import '../../system/widgets/footer.dart';
import '../widgets/features_section.dart';
import '../widgets/section3.dart';
import '../widgets/page_header.dart';
import './baselayout.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  bool showNavbarBackground = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    if (offset > 100 && !showNavbarBackground) {
      setState(() => showNavbarBackground = true);
    } else if (offset <= 100 && showNavbarBackground) {
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
    return BaseLayout(
      stackedChild: PageHeader(
        title: 'خصائص النظام',
        subtitle: 'خصائص النظام/الرئيسية',
      ),
      bodyChild: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50),
          FeaturesSection(),
          Section3(),
          FooterSection(),
        ],
      ),
    );
  }
}
