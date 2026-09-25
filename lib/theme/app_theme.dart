// theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey[50],
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey[900],
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.grey[850],
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple[700],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}