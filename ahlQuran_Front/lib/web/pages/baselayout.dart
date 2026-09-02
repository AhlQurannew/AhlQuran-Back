import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/custom_drawer.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/nav.dart';

class BaseLayout extends StatelessWidget {
  final Widget stackedChild;
  final Widget bodyChild;
  final bool scrollable;
  final bool showDrawer;

  const BaseLayout({
    super.key,
    required this.stackedChild,
    required this.bodyChild,
    this.scrollable = true,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    const double headerHeight = 300;

    return Scaffold(
      key: scaffoldKey,
      drawer: showDrawer ? const CustomDrawer() : null,
      body: scrollable
          ? SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  children: [
                    // Header section with fixed height
                    SizedBox(
                      height: headerHeight,
                      child: Stack(
                        children: [
                          Container(color: theme.colorScheme.primary),
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage('assets/back.png'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withOpacity(0.2),
                                  BlendMode.dstIn,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              NavBar(scaffoldKey: scaffoldKey),
                              Flexible(child: stackedChild),
                            ],
                          ),
                        ],
                      ),
                    ),
                    bodyChild,
                  ],
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Stack(
                    children: [
                      Container(color: theme.colorScheme.primary),
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/back.png'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.2),
                              BlendMode.dstIn,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          NavBar(scaffoldKey: scaffoldKey),
                          Expanded(child: stackedChild),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: bodyChild),
              ],
            ),
    );
  }
}
