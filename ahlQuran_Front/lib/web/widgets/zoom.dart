import 'package:flutter/material.dart';

/// Builds a card with zoom animation on hover, showing icon and text in Arabic
/// Uses app theme for colors and font
class ZoomCard extends StatefulWidget {
  final String title; // Arabic title
  final String price; // Arabic price string
  final String description; // Arabic description
  final IconData icon; // Icon to display

  const ZoomCard({
    required this.title,
    required this.price,
    required this.description,
    required this.icon,
    super.key,
  });

  @override
  ZoomCardState createState() => ZoomCardState();
}

class ZoomCardState extends State<ZoomCard> {
  // Initial scale factor for the card
  static const double _initialScale = 1.0;
  static const double _hoverScale = 1.05;

  double _scale = _initialScale;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _scale = _hoverScale), // Scale up on hover
      onExit: (_) => setState(() => _scale = _initialScale), // Reset scale
      child: SizedBox(
        width: _CardDimensions.width,
        height: _CardDimensions.height,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_scale),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor, // Use app primary color
            borderRadius: BorderRadius.circular(_CardDimensions.borderRadius),
          ),
          padding: const EdgeInsets.all(_CardDimensions.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: _CardDimensions.iconSize,
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
              ),
              const SizedBox(height: _CardDimensions.spacing),
              Text(
                widget.title,
                textDirection: TextDirection.rtl, // Arabic RTL text
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                    ),
              ),
              const SizedBox(height: _CardDimensions.spacingSmall),
              Text(
                'دج ${widget.price}', // Arabic price prefix
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                    ),
              ),
              const SizedBox(height: _CardDimensions.spacingSmall),
              Text(
                widget.description,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Constants for card dimensions
class _CardDimensions {
  static const double width = 100.0;
  static const double height = 160.0;
  static const double borderRadius = 12.0;
  static const double padding = 15.0;
  static const double iconSize = 40.0;
  static const double spacing = 10.0;
  static const double spacingSmall = 5.0;
}
