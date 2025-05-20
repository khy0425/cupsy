import 'package:flutter/material.dart';

/// 앱 테마 및 감정 색상 관리 클래스
class AppTheme {
  /// 주 색상
  static const Color primaryColor = Color(0xFF6A5AE0);
  static const Color secondaryColor = Color(0xFF8F7AEE);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color textColor = Color(0xFF333333);
  static const Color accentColor = Color(0xFFFD8D14);

  /// 텍스트 색상
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);

  /// 다크 테마 색상
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFE0E0E0);
  static const Color primaryDark = Color(0xFF9186EC); // 다크 모드에서 더 밝은 보라색

  /// 감정 색상 매핑 - 기본적인 감정 색상
  static const Map<String, Color> emotionColors = {
    'joy': Color(0xFFFFC107), // 노랑/황금색
    'calm': Color(0xFF4FC3F7), // 하늘색
    'sadness': Color(0xFF7986CB), // 보라/남색
    'anger': Color(0xFFEF5350), // 빨간색
    'anxiety': Color(0xFF78909C), // 회색/청록
    'love': Color(0xFFEC407A), // 분홍/핫핑크
    'boredom': Color(0xFFBDBDBD), // 회색
    'excitement': Color(0xFFFF9800), // 주황색
  };

  /// 다크 모드 지원용 테마 데이터
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, color: textColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
  );

  /// 다크 테마 정의
  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryDark,
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      secondary: secondaryColor,
      background: backgroundDark,
      surface: surfaceDark,
      onBackground: textDark,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textDark),
      bodyMedium: TextStyle(fontSize: 14, color: textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryDark;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryDark.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    dividerColor: Colors.white.withOpacity(0.1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: TextStyle(color: textDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );

  /// 특정 감정에 맞는 색상 가져오기
  static Color getEmotionColor(String emotionId) {
    return emotionColors[emotionId] ?? primaryColor;
  }
}
