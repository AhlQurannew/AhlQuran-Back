import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../controllers/navbar_controller.dart';

class NavBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showBackground;

  NavBar({
    super.key,
    required this.scaffoldKey,
    this.showBackground = false,
  });

  final NavBarController controller = Get.put(NavBarController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = theme.iconTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: showBackground
            ? Colors.white.withOpacity(0.95)
            : Colors.transparent,
        boxShadow: showBackground
            ? [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ]
            : [],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 800;

          return isLargeScreen
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _navItems(theme),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 20.0, left: 20.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.menu, color: iconTheme.color),
                      onPressed: () {
                        scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ),
                );
        },
      ),
    );
  }

  List<Widget> _navItems(ThemeData theme) {
    List<String> titles = [
      'الرئيسية',
      'الأسعار',
      'المزايا',
      'الدعم الفني',
      'التسويق بالعمولة',
      'تسجيل الدخول'
    ];

    controller.initHovered(titles.length);

    return List.generate(titles.length, (index) {
      return GestureDetector(
        onTap: () {
          if (titles[index] == 'تسجيل الدخول') {
            Get.toNamed(Routes.logIn);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => controller.setHovered(index, true),
          onExit: (_) => controller.setHovered(index, false),
          child: Obx(() {
            bool hovered = controller.isHovered.length > index
                ? controller.isHovered[index]
                : false;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (hovered)
                  LayoutBuilder(builder: (context, constraints) {
                    double textWidth = _calculateTextWidth(titles[index]);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: textWidth + 24,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  }),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: hovered
                      ? Matrix4.diagonal3Values(1.1, 1.1, 1)
                      : Matrix4.identity(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    titles[index],
                    style: TextStyle(
                      color:
                          hovered ? theme.colorScheme.secondary : Colors.black,
                      fontWeight: titles[index] == 'تسجيل الدخول'
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  double _calculateTextWidth(String text) {
    const style = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();

    return textPainter.width;
  }
}
