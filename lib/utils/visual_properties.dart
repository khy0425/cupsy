import 'package:flutter/material.dart';

/// 감정의 시각적 표현 속성을 담는 클래스
class VisualProperties {
  final Color color; // 감정 색상
  final double viscosity; // 액체 점도 (0.0 ~ 1.0)
  final String pattern; // 패턴 유형 (wave, bubble, dots, lines 등)
  final double patternDensity; // 패턴 밀도 (0.0 ~ 1.0)
  final double brightness; // 밝기 조정 (0.0 ~ 1.0)
  final double saturation; // 채도 조정 (0.0 ~ 1.0)
  final bool hasFoam; // 거품 여부
  final double foamHeight; // 거품 높이 (0.0 ~ 1.0)
  final int cupStyle; // 컵 스타일 (0: 기본, 1: 와인잔, 2: 머그컵, 3: 유리컵)
  final List<String> specialEffects; // 특수 효과 목록 (sparkle, glow, steam 등)

  const VisualProperties({
    required this.color,
    this.viscosity = 0.5,
    this.pattern = 'none',
    this.patternDensity = 0.5,
    this.brightness = 0.5,
    this.saturation = 0.7,
    this.hasFoam = false,
    this.foamHeight = 0.1,
    this.cupStyle = 0,
    this.specialEffects = const [],
  });

  /// 속성 복사 및 일부 변경
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

  /// 두 VisualProperties 간의 동일성 비교
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VisualProperties) return false;

    return other.color == color &&
        other.viscosity == viscosity &&
        other.pattern == pattern &&
        other.patternDensity == patternDensity &&
        other.brightness == brightness &&
        other.saturation == saturation &&
        other.hasFoam == hasFoam &&
        other.foamHeight == foamHeight &&
        other.cupStyle == cupStyle &&
        _areListsEqual(other.specialEffects, specialEffects);
  }

  /// 리스트 동일성 비교 헬퍼
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      color,
      viscosity,
      pattern,
      patternDensity,
      brightness,
      saturation,
      hasFoam,
      foamHeight,
      cupStyle,
      Object.hashAll(specialEffects),
    );
  }
}
