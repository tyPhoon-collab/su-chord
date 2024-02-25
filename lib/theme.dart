import 'package:flutter/material.dart';

const _themeColor = Colors.green;

final theme = _buildTheme(
  ThemeData.light(useMaterial3: true),
  ColorScheme.fromSeed(seedColor: _themeColor),
);

final darkTheme = _buildTheme(
  ThemeData.dark(useMaterial3: true),
  ColorScheme.fromSeed(seedColor: _themeColor, brightness: Brightness.dark),
);

ThemeData _buildTheme(ThemeData base, ColorScheme colorScheme) {
  return base.copyWith(colorScheme: colorScheme);
}
