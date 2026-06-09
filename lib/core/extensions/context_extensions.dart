import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isWideScreen => screenWidth > 600;

  void showSnackBar(String message, {Color? color, int seconds = 3}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  void showError(String message) =>
      showSnackBar(message, color: Colors.red.shade700);

  void showSuccess(String message) =>
      showSnackBar(message, color: Colors.green);

  void push(Widget page) => Navigator.of(this).push(
        MaterialPageRoute(builder: (_) => page),
      );

  void pushReplacement(Widget page) => Navigator.of(this).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );

  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop(result);
}
