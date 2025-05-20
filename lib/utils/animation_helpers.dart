import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/emotion_model.dart';
import '../models/situation.dart' as sit;
import 'visual_properties.dart' as vp;

/// 애니메이션 유틸리티 클래스
class AnimationHelpers {
  // 감정별 애니메이션 속도 캐시
  static final Map<String, Duration> _emotionDurationCache = {};

  // 감정별 커브 캐시
  static final Map<String, Curve> _emotionCurveCache = {};

  /// 감정에 따른 애니메이션 속도 계산
  static Duration getDurationForEmotion(Emotion emotion) {
    // 캐시된 값이 있으면 사용
    if (_emotionDurationCache.containsKey(emotion.id)) {
      return _emotionDurationCache[emotion.id]!;
    }

    // 감정의 강도와 유형에 따라 애니메이션 속도 결정
    // 높은 에너지/낮은 점도 감정: 빠른 애니메이션
    // 낮은 에너지/높은 점도 감정: 느린 애니메이션

    double speedFactor = 1.0;

    switch (emotion.id) {
      case 'joy':
      case 'excitement':
      case 'anger':
        // 활발한 감정은 빠른 애니메이션
        speedFactor = 0.7;
        break;
      case 'sadness':
      case 'boredom':
      case 'calm':
        // 무거운 감정은 느린 애니메이션
        speedFactor = 1.5;
        break;
      default:
        // 중간 감정은 기본 속도
        speedFactor = 1.0;
    }

    // 점도 기반 추가 조정 (높은 점도 = 느린 애니메이션)
    speedFactor += emotion.viscosity * 0.5;

    // 최종 지속 시간 계산 (기본 800ms)
    final duration = Duration(milliseconds: (800 * speedFactor).round());

    // 캐시에 저장
    _emotionDurationCache[emotion.id] = duration;
    return duration;
  }

  /// 감정에 따른 애니메이션 커브 선택
  static Curve getCurveForEmotion(Emotion emotion) {
    // 캐시된 값이 있으면 사용
    if (_emotionCurveCache.containsKey(emotion.id)) {
      return _emotionCurveCache[emotion.id]!;
    }

    // 감정 특성에 따른 커브 선택
    late Curve curve;

    switch (emotion.id) {
      case 'joy':
      case 'excitement':
        // 활발한 감정은 탄력적인 커브
        curve = Curves.elasticOut;
        break;
      case 'anger':
        // 분노는 빠르게 시작하고 천천히 끝남
        curve = Curves.easeOutQuart;
        break;
      case 'sadness':
      case 'boredom':
        // 천천히 시작하고 천천히 끝남
        curve = Curves.easeInOut;
        break;
      case 'anxiety':
        // 불안은 진동 효과
        curve = Curves.easeInOutBack;
        break;
      case 'love':
        // 사랑은 부드러운 커브
        curve = Curves.easeInOutCubic;
        break;
      case 'calm':
        // 평온함은 매우 부드러운 커브
        curve = Curves.fastLinearToSlowEaseIn;
        break;
      default:
        // 기본 커브
        curve = Curves.easeInOut;
    }

    // 캐시에 저장
    _emotionCurveCache[emotion.id] = curve;
    return curve;
  }

  /// 효율적인 애니메이션 컨트롤러 설정
  static void configureController(
    AnimationController controller,
    Emotion emotion,
  ) {
    controller.duration = getDurationForEmotion(emotion);
  }

  /// 감정 전환 애니메이션 생성
  static Animation<double> createTransitionAnimation(
    AnimationController controller,
    Emotion emotion,
  ) {
    return CurvedAnimation(
      parent: controller,
      curve: getCurveForEmotion(emotion),
    );
  }

  /// 애니메이션 컨트롤러 생성
  static AnimationController createEmotionAnimationController({
    required TickerProvider vsync,
    required Emotion emotion,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: getDurationForEmotion(emotion),
    );
  }

  /// 전환 애니메이션 컨트롤러 생성
  static AnimationController createTransitionController({
    required TickerProvider vsync,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );
  }

  /// 효율적인 애니메이션 세트 생성
  static Map<String, Animation<double>> createEmotionAnimations({
    required AnimationController controller,
    required Emotion emotion,
    required sit.Situation situation,
    required vp.VisualProperties visualProperties,
  }) {
    final Map<String, Animation<double>> animations = {};

    // 기본 웨이브 애니메이션
    animations['wave'] = Tween<double>(
      begin: 0.0,
      end: math.pi * 2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));

    // 거품 애니메이션 (거품이 있는 경우에만)
    if (visualProperties.hasFoam) {
      animations['foam'] = Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }

    // 감정별 특수 효과 애니메이션
    for (String effect in visualProperties.specialEffects) {
      switch (effect) {
        case 'sparkle':
          animations['sparkle'] = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
          break;
        case 'glow':
          animations['glow'] = Tween<double>(begin: 0.3, end: 0.7).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
          break;
        case 'steam':
          animations['steam'] = Tween<double>(
            begin: 0.0,
            end: 5.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
          break;
      }
    }

    return animations;
  }

  /// 감정 시각화 속성 전환 애니메이션
  static Animation<vp.VisualProperties> createVisualTransition({
    required AnimationController controller,
    required vp.VisualProperties begin,
    required vp.VisualProperties end,
  }) {
    return VisualPropertiesTween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// 보간 함수 - 두 값 사이 부드러운 전환
  static double interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  /// 컬러 보간 함수 - 두 색상 사이 부드러운 전환
  static Color interpolateColor(
    Color startColor,
    Color endColor,
    double progress,
  ) {
    return Color.lerp(startColor, endColor, progress) ?? startColor;
  }
}

/// VisualProperties를 애니메이션화하기 위한 Tween
class VisualPropertiesTween extends Tween<vp.VisualProperties> {
  VisualPropertiesTween({
    required vp.VisualProperties begin,
    required vp.VisualProperties end,
  }) : super(begin: begin, end: end);

  @override
  vp.VisualProperties lerp(double t) {
    // 두 VisualProperties 사이를 선형 보간
    final Color lerpedColor = Color.lerp(begin!.color, end!.color, t)!;

    // 점도, 패턴 밀도, 밝기, 채도 보간
    final double lerpedViscosity = _lerpDouble(
      begin!.viscosity,
      end!.viscosity,
      t,
    );
    final double lerpedPatternDensity = _lerpDouble(
      begin!.patternDensity,
      end!.patternDensity,
      t,
    );
    final double lerpedBrightness = _lerpDouble(
      begin!.brightness,
      end!.brightness,
      t,
    );
    final double lerpedSaturation = _lerpDouble(
      begin!.saturation,
      end!.saturation,
      t,
    );

    // 거품 높이 보간
    final double lerpedFoamHeight = _lerpDouble(
      begin!.foamHeight,
      end!.foamHeight,
      t,
    );

    // 거품 여부는 임계점 기준으로 변경 (0.5)
    final bool lerpedHasFoam = t < 0.5 ? begin!.hasFoam : end!.hasFoam;

    // 컵 스타일은 임계점 기준으로 변경 (0.5) - 중간 스타일은 의미가 없음
    final int lerpedCupStyle = t < 0.5 ? begin!.cupStyle : end!.cupStyle;

    // 패턴도 임계점 기준으로 변경 (0.5) - 중간 패턴은 의미가 없음
    final String lerpedPattern = t < 0.5 ? begin!.pattern : end!.pattern;

    // 특수 효과는 t가 0.7 이상이면 end의 효과를 사용
    final List<String> lerpedEffects =
        t < 0.7 ? begin!.specialEffects : end!.specialEffects;

    return vp.VisualProperties(
      color: lerpedColor,
      viscosity: lerpedViscosity,
      pattern: lerpedPattern,
      patternDensity: lerpedPatternDensity,
      brightness: lerpedBrightness,
      saturation: lerpedSaturation,
      hasFoam: lerpedHasFoam,
      foamHeight: lerpedFoamHeight,
      cupStyle: lerpedCupStyle,
      specialEffects: lerpedEffects,
    );
  }

  // 두 더블 값 사이를 선형 보간
  double _lerpDouble(double begin, double end, double t) {
    return begin + (end - begin) * t;
  }
}
