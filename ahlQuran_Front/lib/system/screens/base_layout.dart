import 'package:flutter/material.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/helpers/custom_drawer.dart';
import 'package:get/get.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/controllers/auth_controller.dart';
import 'package:flutter/services.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/messaging_dialog.dart';

class BaseLayout extends StatefulWidget {
  final String title;
  final Widget child;

  const BaseLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  final GlobalKey<ScaffoldState> baseLayoutScaffoldKey =
      GlobalKey<ScaffoldState>();
  bool miniMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          // visible
          return Row(
            children: [
              CustomDrawer(
                miniMode: miniMode,
                onToggleMiniMode: () {
                  setState(() {
                    miniMode = !miniMode;
                  });
                },
              ),
              Expanded(
                child: Scaffold(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: Column(
                    children: [
                      _buildHeader(theme),
                      Expanded(
                          child: SafeArea(
                              child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: widget.child,
                      ))),
                      _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          //  drawer hidden, use endDrawer
          return Scaffold(
            key: baseLayoutScaffoldKey,
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: CustomDrawer(),
            drawerEnableOpenDragGesture: true,
            body: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                    child: SafeArea(
                        child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: widget.child,
                ))),
                _buildFooter(theme),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side (Start in RTL) - Menu Button
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1024) {
                return IconButton(
                  icon: Icon(Icons.menu, color: theme.iconTheme.color),
                  onPressed: () =>
                      baseLayoutScaffoldKey.currentState?.openEndDrawer(),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),

          // Left side (End in RTL) - Action Buttons
          Row(
            children: [
              // Message
              IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    color: theme.iconTheme.color),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const MessagingDialog(),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Logout
              TextButton.icon(
                icon: const Icon(Icons.logout,
                    color: Color(0xFF4CAF50), size: 20), // Green color
                label: const Text(
                  "تسجيل الخروج",
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  try {
                    Get.find<AuthController>().logout();
                  } catch (e) {
                    // Fallback if controller not found
                    Get.offAllNamed('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      alignment: Alignment.center,
      child: Text(
        'جميع الحقوق محفوظة © 2025 نظام أهل القرآن',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
