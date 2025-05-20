import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/emotion_model.dart';
import '../models/situation.dart';
import '../theme/app_theme.dart';
import 'visual_properties.dart' as vp;

/// 감정 시각화 속성 클래스
class VisualProperties {
  /// 컵 색상
  final Color color;

  /// 음료 점도 (0.0~1.0)
  final double viscosity;

  /// 패턴 유형 ('bubble', 'wave', 'dots', 'lines', 'none')
  final String pattern;

  /// 패턴 밀도 (0.0~1.0)
  final double patternDensity;

  /// 밝기 조정 (0.0~1.0)
  final double brightness;

  /// 채도 조정 (0.0~1.0)
  final double saturation;

  /// 거품 여부 (true/false)
  final bool hasFoam;

  /// 거품 높이 (0.0~1.0)
  final double foamHeight;

  /// 컵 스타일 (0: 기본, 1: 와인잔, 2: 머그컵, 3: 유리컵)
  final int cupStyle;

  /// 특수 효과 목록
  final List<String> specialEffects;

  VisualProperties({
    required this.color,
    required this.viscosity,
    required this.pattern,
    this.patternDensity = 0.5,
    this.brightness = 0.5,
    this.saturation = 0.5,
    this.hasFoam = false,
    this.foamHeight = 0.1,
    this.cupStyle = 0,
    this.specialEffects = const [],
  });

  /// 속성 업데이트
  VisualProperties copyWith({
    Color? color,
    double? viscosity,
    String? pattern,
    double? patternDensity,
    double? brightness,
    double? saturation,
    bool? hasFoam,
    double? foamHeight,
    int? cupStyle,
    List<String>? specialEffects,
  }) {
    return VisualProperties(
      color: color ?? this.color,
      viscosity: viscosity ?? this.viscosity,
      pattern: pattern ?? this.pattern,
      patternDensity: patternDensity ?? this.patternDensity,
      brightness: brightness ?? this.brightness,
      saturation: saturation ?? this.saturation,
      hasFoam: hasFoam ?? this.hasFoam,
      foamHeight: foamHeight ?? this.foamHeight,
      cupStyle: cupStyle ?? this.cupStyle,
      specialEffects: specialEffects ?? this.specialEffects,
    );
  }
}

/// 감정-시각화 매핑 클래스
class EmotionVisualizer {
  // 감정-시각 속성 매핑 캐시
  static final Map<String, vp.VisualProperties> _visualPropertiesCache = {};

  // 컵 경로 캐시 - 크기 및 스타일별로 저장
  static final Map<String, Path> _cupPathCache = {};

  /// 감정에서 시각적 속성으로 변환
  static vp.VisualProperties emotionToVisual(
    Emotion emotion,
    Situation situation,
  ) {
    // 캐시 키 생성 (감정 ID + 상황 ID)
    final String cacheKey = '${emotion.id}_${situation.id}';

    // 캐시된 값이 있으면 사용
    if (_visualPropertiesCache.containsKey(cacheKey)) {
      return _visualPropertiesCache[cacheKey]!;
    }

    // 기본 색상 (감정 색상 사용)
    final Color baseColor =
        AppTheme.emotionColors[emotion.colorName] ?? AppTheme.primaryColor;

    // 기본 점도 (감정의 강도에 따라 다름)
    final double baseViscosity = emotion.viscosity;

    // 기본 패턴 (감정의 패턴 사용)
    final String basePattern = emotion.pattern;

    // 기본 시각적 속성
    vp.VisualProperties properties = vp.VisualProperties(
      color: baseColor,
      viscosity: baseViscosity,
      pattern: basePattern,
    );

    // 감정 ID에 따른 특수 속성 적용
    properties = _applyEmotionSpecificProperties(properties, emotion);

    // 상황에 따른 속성 조정
    properties = _adjustForSituation(properties, situation);

    // 캐시에 저장
    _visualPropertiesCache[cacheKey] = properties;

    return properties;
  }

  /// 감정별 특수 속성 적용
  static vp.VisualProperties _applyEmotionSpecificProperties(
    vp.VisualProperties properties,
    Emotion emotion,
  ) {
    // 감정별 특수 효과 설정
    switch (emotion.id) {
      case 'joy':
        properties = properties.copyWith(
          brightness: 0.7,
          patternDensity: 0.7,
          saturation: 0.9,
          specialEffects: ['sparkle'],
          cupStyle: 1, // 와인잔
        );
        break;
      case 'calm':
        properties = properties.copyWith(
          brightness: 0.6,
          patternDensity: 0.3,
          hasFoam: false,
          cupStyle: 3, // 유리컵
        );
        break;
      case 'sadness':
        properties = properties.copyWith(
          brightness: 0.4,
          saturation: 0.5,
          specialEffects: ['raindrops'],
          cupStyle: 0, // 기본
        );
        break;
      case 'anger':
        properties = properties.copyWith(
          brightness: 0.6,
          saturation: 1.0,
          hasFoam: true,
          foamHeight: 0.2,
          specialEffects: ['steam'],
          cupStyle: 2, // 머그컵
        );
        break;
      case 'anxiety':
        properties = properties.copyWith(
          brightness: 0.4,
          patternDensity: 0.8,
          specialEffects: ['bubbles'],
          cupStyle: 0, // 기본
        );
        break;
      case 'love':
        properties = properties.copyWith(
          brightness: 0.6,
          saturation: 0.8,
          specialEffects: ['glow'],
          cupStyle: 1, // 와인잔
        );
        break;
      case 'boredom':
        properties = properties.copyWith(
          brightness: 0.3,
          saturation: 0.3,
          patternDensity: 0.2,
          cupStyle: 2, // 머그컵
        );
        break;
      case 'excitement':
        properties = properties.copyWith(
          brightness: 0.7,
          saturation: 0.9,
          patternDensity: 0.9,
          hasFoam: true,
          foamHeight: 0.15,
          specialEffects: ['fizz', 'sparkle'],
          cupStyle: 3, // 유리컵
        );
        break;
    }
    return properties;
  }

  /// 상황에 따른 속성 조정
  static vp.VisualProperties _adjustForSituation(
    vp.VisualProperties properties,
    Situation situation,
  ) {
    // 상황에 따른 추가 조정
    switch (situation.id) {
      case 'work':
        properties = properties.copyWith(
          cupStyle: 2, // 직장은 머그컵
          specialEffects:
              situation.id == 'anxiety'
                  ? [...properties.specialEffects, 'steam']
                  : properties.specialEffects,
        );
        break;
      case 'hobby':
        if (properties.specialEffects.contains('joy') ||
            properties.specialEffects.contains('excitement')) {
          properties = properties.copyWith(
            specialEffects: [...properties.specialEffects, 'sparkle'],
          );
        }
        break;
      case 'health':
        if (properties.cupStyle == 0) {
          properties = properties.copyWith(
            cupStyle: 2,
            hasFoam: true,
            foamHeight: 0.1,
          );
        }
        break;
      case 'home':
        if (properties.cupStyle == 0) {
          properties = properties.copyWith(
            cupStyle: 2, // 집에서는 주로 머그컵
          );
        }
        break;
    }
    return properties;
  }

  /// 컵 경로 생성
  static Path getCupPath(int style, Size size) {
    // 캐시 키 생성 (스타일 + 크기)
    final String cacheKey =
        '$style-${size.width.toStringAsFixed(1)}-${size.height.toStringAsFixed(1)}';

    // 캐시된 경로가 있으면 사용
    if (_cupPathCache.containsKey(cacheKey)) {
      return _cupPathCache[cacheKey]!.shift(Offset.zero); // 복사본 반환
    }

    final Path path = Path();

    // 컵 크기 계산
    final double width = size.width * 0.8;
    final double height = size.height * 0.85;
    final double left = (size.width - width) / 2;
    final double top = (size.height - height) / 2;

    switch (style) {
      case 1: // 와인잔
        _drawWineGlassPath(path, left, top, width, height);
        break;
      case 2: // 머그컵
        _drawMugPath(path, left, top, width, height);
        break;
      case 3: // 유리컵
        _drawGlassPath(path, left, top, width, height);
        break;
      default: // 기본 컵
        _drawDefaultCupPath(path, left, top, width, height);
    }

    // 캐시에 저장
    _cupPathCache[cacheKey] = Path.from(path);
    return path;
  }

  // 기본 컵 모양
  static void _drawDefaultCupPath(
    Path path,
    double left,
    double top,
    double width,
    double height,
  ) {
    final double bottom = top + height;
    final double right = left + width;

    // 컵 상단 (약간의 커브)
    path.moveTo(left, top);
    path.quadraticBezierTo(left + width / 2, top - height * 0.03, right, top);

    // 컵의 오른쪽 측면
    path.lineTo(right - width * 0.1, bottom);

    // 컵 바닥 (약간의 커브)
    path.quadraticBezierTo(
      left + width / 2,
      bottom + height * 0.02,
      left + width * 0.1,
      bottom,
    );

    // 컵의 왼쪽 측면
    path.lineTo(left, top);
    path.close();
  }

  // 와인잔 모양
  static void _drawWineGlassPath(
    Path path,
    double left,
    double top,
    double width,
    double height,
  ) {
    final double bottom = top + height;
    final double right = left + width;
    final double stemWidth = width * 0.1;
    final double bowlHeight = height * 0.5;
    final double stemHeight = height * 0.3;
    final double baseHeight = height * 0.2;

    // 와인잔 볼(상단) 부분
    path.moveTo(left, top + bowlHeight);
    path.quadraticBezierTo(
      left + width / 2,
      top - height * 0.05,
      right,
      top + bowlHeight,
    );

    // 오른쪽 스템으로 연결
    path.lineTo(
      left + width / 2 + stemWidth / 2,
      top + bowlHeight + stemHeight,
    );

    // 베이스(하단) 부분
    path.lineTo(right - width * 0.2, bottom);
    path.quadraticBezierTo(
      left + width / 2,
      bottom + height * 0.02,
      left + width * 0.2,
      bottom,
    );

    // 왼쪽 스템으로 연결
    path.lineTo(
      left + width / 2 - stemWidth / 2,
      top + bowlHeight + stemHeight,
    );

    // 볼 부분 닫기
    path.lineTo(left, top + bowlHeight);
    path.close();
  }

  // 머그컵 모양
  static void _drawMugPath(
    Path path,
    double left,
    double top,
    double width,
    double height,
  ) {
    final double bottom = top + height;
    final double right = left + width;

    // 컵 상단
    path.moveTo(left, top);
    path.lineTo(right, top);

    // 컵 오른쪽 측면
    path.lineTo(right, bottom - height * 0.1);

    // 컵 바닥 (곡선)
    path.quadraticBezierTo(
      left + width / 2,
      bottom + height * 0.02,
      left,
      bottom - height * 0.1,
    );

    // 컵 왼쪽 측면
    path.lineTo(left, top);
    path.close();

    // 손잡이는 EmotionCupPainter._drawCupHandle에서 그림
  }

  // 유리컵 모양
  static void _drawGlassPath(
    Path path,
    double left,
    double top,
    double width,
    double height,
  ) {
    final double bottom = top + height;
    final double right = left + width;

    // 컵 상단 (직선)
    path.moveTo(left + width * 0.1, top);
    path.lineTo(right - width * 0.1, top);

    // 컵 오른쪽 측면 (약간 안쪽으로 기울어짐)
    path.quadraticBezierTo(
      right,
      top + height / 2,
      right - width * 0.05,
      bottom - height * 0.05,
    );

    // 컵 바닥 (두꺼움)
    path.lineTo(right - width * 0.05, bottom);
    path.lineTo(left + width * 0.05, bottom);
    path.lineTo(left + width * 0.05, bottom - height * 0.05);

    // 컵 왼쪽 측면
    path.quadraticBezierTo(left, top + height / 2, left + width * 0.1, top);

    path.close();
  }

  /// 색상 조정 (밝기, 채도)
  static Color adjustColor(Color color, double brightness, double saturation) {
    // HSL 색상 모델로 변환하여 조정
    final HSLColor hsl = HSLColor.fromColor(color);

    // 밝기 및 채도 조정 (0.0-1.0 범위)
    return hsl
        .withLightness((hsl.lightness + brightness) / 2)
        .withSaturation(saturation)
        .toColor();
  }
}
