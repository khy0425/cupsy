import 'package:flutter/material.dart';

/// Cupsy 앱의 테마를 정의하는 클래스입니다.
class AppTheme {
  // 프라이머리 색상 - 차분한 민트색
  static const Color primaryColor = Color(0xFF82C8C1);

  // 감정 관련 색상들
  static const Map<String, Color> emotionColors = {
    'joy': Color(0xFFFFC857), // 기쁨 - 밝은 노랑
    'calm': Color(0xFF82C8C1), // 평온 - 민트
    'sadness': Color(0xFF577590), // 슬픔 - 파랑
    'anger': Color(0xFFEF5350), // 분노 - 빨강
    'anxiety': Color(0xFFD3A588), // 불안 - 브라운
    'love': Color(0xFFF582AE), // 사랑 - 핑크
    'boredom': Color(0xFFB8BAC0), // 지루함 - 회색
    'excitement': Color(0xFFDC965A), // 신남 - 오렌지
  };

  // 배경 색상
  static const Color backgroundColor = Color(0xFFF7F7F7);

  // 텍스트 색상
  static const Color textPrimaryColor = Color(0xFF444444);
  static const Color textSecondaryColor = Color(0xFF7D7D7D);

  // 앱 라이트 테마
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: Color(0xFFF582AE),
      surface: Colors.white,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16),
      bodyMedium: TextStyle(color: textPrimaryColor, fontSize: 14),
      bodySmall: TextStyle(color: textSecondaryColor, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // 특정 감정에 따른 색상 가져오기
  static Color getEmotionColor(String emotion) {
    return emotionColors[emotion] ?? primaryColor;
  }
}
