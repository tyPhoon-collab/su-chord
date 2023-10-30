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
  // final inputDecorationTheme = InputDecorationTheme(
  //   border: OutlineInputBorder(
  //     borderRadius: BorderRadius.circular(30),
  //   ),
  // );
  // const bottomNavigationBarTheme = BottomNavigationBarThemeData(
  //   selectedIconTheme: IconThemeData(size: 32),
  // );

  return base.copyWith(
    colorScheme: colorScheme,
    // bottomNavigationBarTheme: bottomNavigationBarTheme,
    // inputDecorationTheme: inputDecorationTheme,
    // listTileTheme: ListTileThemeData(
    //   titleTextStyle: base.textTheme.labelMedium!.copyWith(
    //     fontWeight: FontWeight.bold,
    //     fontSize: 16,
    //   ),
    // ),
    // textTheme: _buildTextTheme(base.textTheme, colorScheme)
    //     .apply(fontFamily: 'ZenMaruGothic'),
  );
}
