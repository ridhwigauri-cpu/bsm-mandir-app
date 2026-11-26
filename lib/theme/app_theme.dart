import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: C.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: C.maroon3,
        onPrimary: C.creamText,
        secondary: C.gold,
        onSecondary: C.onGold,
        surface: C.paper,
        onSurface: C.ink,
        error: C.red,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: C.ink,
        displayColor: C.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: C.deep,
        foregroundColor: C.creamText,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: C.ink,
        contentTextStyle: TextStyle(color: C.creamText, fontSize: 12.5),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: C.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.goldDeep, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFFB7A5A9), fontSize: 13),
      ),
    );
  }
}

/// ऐप के अंदर इस्तेमाल होने वाले सामान्य टेक्स्ट स्टाइल
class T {
  const T._();

  static const cardTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: C.maroon,
  );

  static const label = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: C.ink2,
  );

  static const body = TextStyle(fontSize: 12, color: C.ink2, height: 1.45);

  static const muted = TextStyle(fontSize: 11, color: C.ink3, height: 1.5);

  static const kvLeft = TextStyle(fontSize: 12.5, color: C.ink2);

  static const kvRight = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: C.maroon,
  );

  static const btn = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

  static const btnSmall = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);
}
