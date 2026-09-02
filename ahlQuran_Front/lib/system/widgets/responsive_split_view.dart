import 'package:flutter/material.dart';

/// A responsive layout that conditionally displays a secondary child
/// when the screen width exceeds a certain breakpoint.
/// Useful for creating layouts that adapt between mobile and larger screens.
class ResponsiveSplitView extends StatelessWidget {
  final Widget primaryChild; // Always visible
  final Widget secondaryChild; // Visible only on wide screens
  final double breakpoint; // Width threshold for showing secondaryChild

  const ResponsiveSplitView({
    super.key,
    required this.primaryChild,
    required this.secondaryChild,
    this.breakpoint = 600, // Default breakpoint (e.g. tablet and up)
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > breakpoint;

    final ThemeData theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Main content always shown
          Expanded(
            flex: 1,
            child: ColoredBox(
              color: surfaceColor,
              child: Center(child: primaryChild),
            ),
          ),

          // Secondary content only shown on wide screens
          if (isWideScreen)
            Expanded(
              flex: 1,
              child: secondaryChild,
            ),
        ],
      ),
    );
  }
}
