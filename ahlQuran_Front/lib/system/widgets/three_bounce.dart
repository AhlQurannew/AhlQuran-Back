import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

class ThreeBounce extends StatelessWidget {
  const ThreeBounce({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SpinKitThreeBounce(
        color: theme.primaryColor,
        size: 30.0,
      ),
    );
  }
}
