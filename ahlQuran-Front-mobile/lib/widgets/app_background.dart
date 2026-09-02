import 'dart:ui';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF), // White at top
            Color(0xFF999999), // Gray at bottom
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ellipse 1 - Orange blur on top left
          Positioned(
            left: -229,
            top: -163,
            child: Container(
              width: 582,
              height: 582,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8800).withValues(alpha: 0.8),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 184.143, sigmaY: 184.143),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // Ellipse 2 - Red blur on bottom right
          Positioned(
            right: -586,
            top: 419,
            child: Container(
              width: 934,
              height: 934,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6200).withValues(alpha: 0.8),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 295.515, sigmaY: 295.515),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // Child content
          child,
        ],
      ),
    );
  }
}
