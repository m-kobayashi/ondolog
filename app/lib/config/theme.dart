import 'package:flutter/material.dart';

/// アプリのテーマ設定
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // ブルー
        brightness: Brightness.light,
      ),
      useMaterial3: true,

      // AppBar設定
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),

      // カード設定
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ボタン設定
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // 入力フィールド設定
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  // カラー定義
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // 温度ステータスカラー
  static Color getTemperatureStatusColor(bool isAbnormal) {
    return isAbnormal ? errorColor : successColor;
  }
}
