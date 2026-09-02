import 'package:flutter/material.dart';

// SectionHeader with optional animated divider and subheader.
class SectionHeader extends StatefulWidget {
  final String header;
  final String? subheader;

  const SectionHeader({
    super.key,
    required this.header,
    this.subheader,
  });

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Controls the animation loop: slow (4 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Simple linear animation from 0 to 1
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main title text
        Text(
          widget.header,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),

        // Animated custom divider
        SizedBox(
          height: 4,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final dividerWidth = totalWidth * 0.3; // Short divider (40%)
                  final gapWidth = 20.0; // Width of the moving white space
                  final left =
                      _animation.value * (dividerWidth + gapWidth) - gapWidth;

                  return Stack(
                    children: [
                      // Static colored line (centered)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: dividerWidth,
                          height: 4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // Moving white gap across the divider
                      Positioned(
                        left: (totalWidth - dividerWidth) / 2 + left,
                        child: Container(
                          width: gapWidth,
                          height: 4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // Optional subheader text
        if (widget.subheader != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subheader!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
