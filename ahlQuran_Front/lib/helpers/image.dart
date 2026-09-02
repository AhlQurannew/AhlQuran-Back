import 'package:flutter/material.dart';

class CustomAssetImage extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;

  const CustomAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
  });

  @override
  State<CustomAssetImage> createState() => _CustomAssetImageState();
}

class _CustomAssetImageState extends State<CustomAssetImage> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Image.asset(
        widget.assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.error,
            color: colorScheme.error,
          );
        },
      ),
    );
  }
}
