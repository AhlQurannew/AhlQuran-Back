import 'package:flutter/material.dart';

import 'user_card.dart'; // Ensure this file exists and is properly structured

/// A section displaying a grid of user cards with hover effects, showcasing system users.
/// Uses app theme colors and font. Supports Arabic RTL text.
class UsersSection extends StatelessWidget {
  const UsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: _Dimensions.verticalPadding,
          horizontal: _Dimensions.horizontalPadding,
        ),
        child: Column(
          children: [
            Text(
              'مستخدمو النظام',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: _Dimensions.spacingSmall),
            Text(
              'يوفر النظام خدمات ومزايا عديدة لمختلف مستخدميه.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: _Dimensions.spacing),
            GridView.count(
              crossAxisCount: _getCrossAxisCount(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: _Dimensions.gridSpacing,
              mainAxisSpacing: _Dimensions.gridSpacing,
              children: const [
                HoverUserCard(
                  imagePath: _AssetPaths.parent,
                  title: 'ولي الأمر',
                ),
                HoverUserCard(
                  imagePath: _AssetPaths.student,
                  title: 'الطالب',
                ),
                HoverUserCard(
                  imagePath: _AssetPaths.teacher,
                  title: 'المعلم',
                ),
                HoverUserCard(
                  imagePath: _AssetPaths.admin,
                  title: 'المشرف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Determines the number of columns based on screen width.
  int _getCrossAxisCount(BuildContext context) {
    return MediaQuery.of(context).size.width > _Dimensions.breakpoint ? 4 : 1;
  }
}

/// A card widget that elevates slightly on hover, wrapping a UserCard.
class HoverUserCard extends StatefulWidget {
  final String imagePath; // Path to the image asset
  final String title; // Arabic title of the user type

  const HoverUserCard({
    required this.imagePath,
    required this.title,
    super.key,
  });

  @override
  HoverUserCardState createState() => HoverUserCardState();
}

class HoverUserCardState extends State<HoverUserCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), // Elevate on hover
      onExit: (_) => setState(() => _isHovered = false), // Reset on exit
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -_Dimensions.hoverElevation, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_Dimensions.borderRadius),
          boxShadow: _isHovered ? [_HoverStyles.boxShadow] : [],
        ),
        child: UserCard(
          imagePath: widget.imagePath,
          title: widget.title,
        ),
      ),
    );
  }
}

/// Constants for dimensions and styling
class _Dimensions {
  static const double verticalPadding = 50.0;
  static const double horizontalPadding = 20.0;
  static const double spacing = 20.0;
  static const double spacingSmall = 8.0;
  static const double gridSpacing = 20.0;
  static const double breakpoint = 800.0;
  static const double borderRadius = 10.0;
  static const double hoverElevation = 5.0;
}

/// Constants for asset paths
class _AssetPaths {
  static const String parent = 'assets/images1/parent.png';
  static const String student = 'assets/images1/student.png';
  static const String teacher = 'assets/images1/teacher.png';
  static const String admin = 'assets/images1/admin.png';
}

/// Constants for hover styles
class _HoverStyles {
  static const BoxShadow boxShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 8.0,
    spreadRadius: 2.0,
    offset: Offset(0, 4),
  );
}
