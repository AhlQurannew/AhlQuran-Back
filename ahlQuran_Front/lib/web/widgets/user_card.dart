import 'package:flutter/material.dart';

/// A card widget displaying a user's image and title, used within a hoverable container.
/// Uses app theme colors, fonts, and supports Arabic RTL text.
class UserCard extends StatelessWidget {
  final String imagePath; // Path to the user image asset
  final String title; // Arabic title for the user type

  const UserCard({
    required this.imagePath,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _CardStyles.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_CardStyles.borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(_CardStyles.imagePadding),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error_outline,
                  size: _CardStyles.iconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: _CardStyles.textPadding,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

/// Constants for card styling
class _CardStyles {
  static const double elevation = 4.0;
  static const double borderRadius = 12.0;
  static const double imagePadding = 8.0;
  static const double textPadding = 8.0;
  static const double iconSize = 40.0;
}
