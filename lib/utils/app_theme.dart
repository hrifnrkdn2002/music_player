import 'package:flutter/material.dart';

class AppTheme {
  final bool isDark;

  const AppTheme(this.isDark);

  Color get background => isDark ? const Color(0xFF121212) : Colors.white;

  Color get surface => isDark ? const Color(0xFF1C1C1C) : Colors.grey.shade200;

  Color get text => isDark ? Colors.white : Colors.black;

  Color get subtitle => isDark ? Colors.white70 : Colors.grey.shade600;

  Color get accent => isDark ? Colors.purpleAccent : Colors.purple;
}
