import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Colors.red;
  static const Color primaryDark = Color(0xFFD32F2F); // red.shade700

  // Surface — Light
  static const Color surfaceLight = Colors.white;
  static const Color appBarLight = Colors.white;
  static const Color navBarLight = Colors.white;
  static const Color cardLight = Colors.white;

  // Surface — Dark
  static const Color surfaceDark = Color(0xFF121212);
  static const Color appBarDark = Color(0xFF1B1B1B); // grey.shade900
  static const Color navBarDark = Color(0xFF1B1B1B);
  static const Color cardDark = Color(0xFF2C2C2C); // grey[850]

  // Text
  static const Color textLight = Colors.black;
  static const Color textDark = Colors.white;

  // Icon
  static const Color iconSelected = Colors.red;
  static const Color iconUnselected = Colors.grey;

  // Feedback
  static const Color success = Colors.green;
  static const Color error = Colors.red;
}
