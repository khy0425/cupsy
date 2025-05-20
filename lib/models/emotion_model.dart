import 'package:cupsy/models/situation.dart';
import 'package:flutter/material.dart';

/// 감정 모델 클래스
class Emotion {
  final String id; // 고유 식별자
  final String name; // 감정 이름
  final Color color; // 감정 색상
  final String colorName; // 감정 색상 이름
  final String description; // 감정 설명
  final String iconPath; // 아이콘 경로
  final double intensity; // 감정 강도 (0.0-1.0)
  final double viscosity; // 점성도
  final String pattern; // 패턴

  Emotion({
    required this.id,
    required this.name,
    required this.color,
    this.colorName = '',
    this.description = '',
    this.iconPath = '',
    this.intensity = 0.5,
    this.viscosity = 0.5,
    this.pattern = 'default',
  });

  // JSON 변환 생성자
  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      colorName: json['colorName'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      intensity: json['intensity'] ?? 0.5,
      viscosity: json['viscosity'] ?? 0.5,
      pattern: json['pattern'] ?? 'default',
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'colorName': colorName,
      'description': description,
      'iconPath': iconPath,
      'intensity': intensity,
      'viscosity': viscosity,
      'pattern': pattern,
    };
  }
}

/// 생성된 감정 컵 클래스
class EmotionCup {
  final String id;
  final Emotion emotion;
  final Situation situation;
  final DateTime createdAt;
  final String imagePath; // 생성된 이미지 경로 (선택적)
  final String title; // 감정 컵 제목
  final String description; // 감정 컵 설명

  EmotionCup({
    required this.id,
    required this.emotion,
    required this.situation,
    required this.createdAt,
    this.imagePath = '',
    required this.title,
    required this.description,
  });
}

/// 사전 정의된 감정 목록
class EmotionData {
  static List<Emotion> emotions = [
    Emotion(
      id: 'joy',
      name: '기쁨',
      color: Colors.amber.shade400,
      colorName: 'amber',
      description: '만족감과 행복을 느끼는 긍정적인 감정',
      iconPath: 'assets/images/emotions/joy.png',
      intensity: 0.8,
      viscosity: 0.3,
      pattern: 'bubble',
    ),
    Emotion(
      id: 'calm',
      name: '평온',
      color: Colors.teal.shade300,
      colorName: 'teal',
      description: '안정되고 균형 잡힌 마음의 상태',
      iconPath: 'assets/images/emotions/calm.png',
      intensity: 0.4,
      viscosity: 0.7,
      pattern: 'smooth',
    ),
    Emotion(
      id: 'sadness',
      name: '슬픔',
      color: Colors.blue.shade300,
      colorName: 'blue',
      description: '상실감이나 실망감에서 오는 우울한 감정',
      iconPath: 'assets/images/emotions/sadness.png',
      intensity: 0.6,
      viscosity: 0.8,
      pattern: 'ripple',
    ),
    Emotion(
      id: 'anger',
      name: '분노',
      color: Colors.red.shade400,
      colorName: 'red',
      description: '불만이나 적대감에서 비롯된 강렬한 감정',
      iconPath: 'assets/images/emotions/anger.png',
      intensity: 0.9,
      viscosity: 0.2,
      pattern: 'wave',
    ),
    Emotion(
      id: 'anxiety',
      name: '불안',
      color: Colors.purple.shade300,
      colorName: 'purple',
      description: '걱정과 두려움이 섞인 불편한 감정',
      iconPath: 'assets/images/emotions/anxiety.png',
      intensity: 0.7,
      viscosity: 0.5,
      pattern: 'static',
    ),
    Emotion(
      id: 'love',
      name: '사랑',
      color: Colors.pink.shade300,
      colorName: 'pink',
      description: '타인에 대한 깊은 애정과 친밀함',
      iconPath: 'assets/images/emotions/love.png',
      intensity: 0.9,
      viscosity: 0.4,
      pattern: 'heart',
    ),
    Emotion(
      id: 'boredom',
      name: '지루함',
      color: Colors.grey.shade400,
      colorName: 'grey',
      description: '심심하고 무료한 감정',
      iconPath: '',
      intensity: 0.9,
      viscosity: 0.6,
      pattern: 'flat',
    ),
    Emotion(
      id: 'excitement',
      name: '신남',
      color: Colors.yellow.shade400,
      colorName: 'yellow',
      description: '들떠있고 기대되는 감정',
      iconPath: '',
      intensity: 0.2,
      viscosity: 0.3,
      pattern: 'sparkle',
    ),
  ];
}

/// 사전 정의된 상황 목록
class SituationData {
  static List<Situation> situations = [
    Situation(
      id: 'work',
      name: '일/학교',
      description: '일이나 학교에서 느끼는 감정',
      icon: 'work',
    ),
    Situation(
      id: 'relationship',
      name: '인간관계',
      description: '타인과의 관계에서 느끼는 감정',
      icon: 'people',
    ),
    Situation(
      id: 'hobby',
      name: '취미/여가',
      description: '취미나 여가 활동에서 느끼는 감정',
      icon: 'hobby',
    ),
    Situation(
      id: 'health',
      name: '건강/컨디션',
      description: '건강이나 컨디션과 관련된 감정',
      icon: 'health',
    ),
    Situation(
      id: 'home',
      name: '집/가족',
      description: '집이나 가족과 관련된 감정',
      icon: 'home',
    ),
    Situation(
      id: 'growth',
      name: '성장/발전',
      description: '자기 성장이나 발전에 관한 감정',
      icon: 'growth',
    ),
    Situation(
      id: 'other',
      name: '기타',
      description: '다른 상황에서 느끼는 감정',
      icon: 'other',
    ),
  ];
}
