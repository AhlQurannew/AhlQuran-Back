import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardTileConfig {
  final String label;
  final IconData icon;
  final IconData bigIcon;
  final Widget Function()? page;
  final String? route;
  final String? count;
  final bool isWide;
  final Color? backgroundColor;

  DashboardTileConfig({
    required this.label,
    required this.icon,
    required this.bigIcon,
    this.page,
    this.route,
    this.count,
    this.isWide = false,
    this.backgroundColor,
  });
}

//
class DashboardTile extends StatefulWidget {
  final DashboardTileConfig config;

  const DashboardTile({required this.config, super.key});

  @override
  State<DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<DashboardTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        widget.config.backgroundColor ?? theme.colorScheme.primaryContainer;
    final onColor = widget.config.backgroundColor != null
        ? Colors.white
        : theme.colorScheme.onPrimaryContainer;

    final scale = _hovering ? 1.04 : 1.0;
    final iconScale = _hovering ? 1.14 : 1.0;
    final iconRotation = _hovering ? 0.05 : 0.0;
    const duration = Duration(milliseconds: 200);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {
          if (widget.config.route != null) {
            Get.toNamed(widget.config.route!);
          } else if (widget.config.page != null) {
            Get.to(widget.config.page!());
          }
        },
        child: AnimatedScale(
          scale: scale,
          duration: duration,
          curve: Curves.ease,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Background icon (left side, same position)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: AnimatedRotation(
                      turns: iconRotation,
                      duration: duration,
                      curve: Curves.ease,
                      child: AnimatedScale(
                        scale: iconScale,
                        duration: duration,
                        curve: Curves.ease,
                        child: Opacity(
                          opacity: 0.13,
                          child: Icon(
                            widget.config.bigIcon,
                            size: 62,
                            color: onColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content: 3 columns from left to right (icon, name, number)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Column 1: Icon (left)
                        Icon(
                          widget.config.icon,
                          color: onColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        // Column 2: Name
                        Text(
                          widget.config.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Column 3: Number (right)
                        if (widget.config.count != null)
                          Text(
                            widget.config.count!,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: onColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
