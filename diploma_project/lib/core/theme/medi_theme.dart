import 'package:flutter/material.dart';

/// Фиолетовая палитра по макетам MEDI
class MediColors {
  MediColors._();

  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryDark = Color(0xFF5B2D8E);
  static const Color fieldBg = Color(0xFFEDE7F6);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color text = Color(0xFF333333);
  static const Color textMuted = Color(0xFF888888);

  /// Макет главной / навигации
  static const Color homeBackground = Color(0xFFF8F9FE);
  static const Color accentPurple = Color(0xFF7B61FF);
  /// Нижняя навигация (светлая панель по макету)
  static const Color bottomNavBarBg = Color(0xFFF2F2F7);
  static const Color bottomNavIconInactive = Color(0xFF1C1C1E);
  static const Color bottomNavPill = Color(0xFF6C63FF);
  static const Color navBarDark = Color(0xFF1E1E24);
  static const Color segmentTrack = Color(0xFFFFFFFF);
  static const Color segmentActive = Color(0xFFE8E0FF);

  /// Шапка главной (макет)
  static const Color greetingPurple = Color(0xFF6C5CE7);
  /// Активная вкладка «Ваш рецепт» / «Прогресс»
  static const Color tabActiveLavender = Color(0xFFE8E4FF);
  static const Color headerChipBg = Color(0xFFF0F0F5);
  static const Color headerSubtitle = Color(0xFF9B97C8);

  /// Экран чата (пузыри)
  static const Color chatUserBubble = Color(0xFFE8E4FF);
  static const Color chatBubbleText = Color(0xFF4A3F8C);
  static const Color chatAiBorder = Color(0xFFE0DCF5);
  static const Color chatTimestamp = Color(0xFF9E9EB0);
}

ThemeData buildMediTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MediColors.primary,
      primary: MediColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: '.SF Pro Text',
      bodyColor: MediColors.text,
      displayColor: MediColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: MediColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MediColors.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MediColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
