/// 감정 모델 클래스
class Emotion {
  final String id;
  final String name;
  final String description;
  final String colorName; // emotionColors 맵의 키와 매칭
  final double viscosity; // 점도 (0.0 ~ 1.0)
  final String pattern; // 패턴 유형 (ex: 'wave', 'bubble', 'dots', 'lines')

  Emotion({
    required this.id,
    required this.name,
    required this.description,
    required this.colorName,
    required this.viscosity,
    required this.pattern,
  });
}

/// 상황 모델 클래스
class Situation {
  final String id;
  final String name;
  final String description;
  final String icon; // 아이콘 이름

  Situation({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
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
      description: '행복하고 즐거운 감정',
      colorName: 'joy',
      viscosity: 0.4,
      pattern: 'bubble',
    ),
    Emotion(
      id: 'calm',
      name: '평온',
      description: '편안하고 차분한 감정',
      colorName: 'calm',
      viscosity: 0.7,
      pattern: 'wave',
    ),
    Emotion(
      id: 'sadness',
      name: '슬픔',
      description: '우울하고 슬픈 감정',
      colorName: 'sadness',
      viscosity: 0.8,
      pattern: 'dots',
    ),
    Emotion(
      id: 'anger',
      name: '분노',
      description: '화가 나고 짜증나는 감정',
      colorName: 'anger',
      viscosity: 0.6,
      pattern: 'lines',
    ),
    Emotion(
      id: 'anxiety',
      name: '불안',
      description: '걱정되고 초조한 감정',
      colorName: 'anxiety',
      viscosity: 0.5,
      pattern: 'wave',
    ),
    Emotion(
      id: 'love',
      name: '사랑',
      description: '사랑스럽고 따뜻한 감정',
      colorName: 'love',
      viscosity: 0.3,
      pattern: 'bubble',
    ),
    Emotion(
      id: 'boredom',
      name: '지루함',
      description: '심심하고 무료한 감정',
      colorName: 'boredom',
      viscosity: 0.9,
      pattern: 'dots',
    ),
    Emotion(
      id: 'excitement',
      name: '신남',
      description: '들떠있고 기대되는 감정',
      colorName: 'excitement',
      viscosity: 0.2,
      pattern: 'lines',
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
