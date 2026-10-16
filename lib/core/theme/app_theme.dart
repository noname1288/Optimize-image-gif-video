import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light =>
      ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.deepPurple,
  );
}
