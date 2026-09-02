import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: Color(0xFFC78D20),
      primaryContainer: Color(0xFFDEB059),
      secondary: Color(0xFF8D9440),
      secondaryContainer: Color(0xFFBFC39B),
      tertiary: Color(0xFF616247),
      tertiaryContainer: Color(0xFFBCBCA8),
      appBarColor: Color(0xFFBFC39B),
      error: Color(0xFFB00020),
      errorContainer: Color(0xFFFFDAD6),
    ),
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    fontFamily: 'JannaLT', // JannaLT font globally
  );

  static ThemeData dark = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: Color(0xFFDEB059),
      primaryContainer: Color(0xFFC78D20),
      primaryLightRef: Color(0xFFC78D20),
      secondary: Color(0xFFAFB479),
      secondaryContainer: Color(0xFF82883D),
      secondaryLightRef: Color(0xFF8D9440),
      tertiary: Color(0xFF81816C),
      tertiaryContainer: Color(0xFF5A5A35),
      tertiaryLightRef: Color(0xFF616247),
      appBarColor: Color(0xFFBFC39B),
      error: Color(0xFFCF6679),
      errorContainer: Color(0xFF93000A),
    ),
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    fontFamily: 'JannaLT', // JannaLT font for dark theme
  );
}
