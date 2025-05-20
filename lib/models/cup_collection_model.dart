import 'package:cupsy/models/emotion_model.dart';
import 'package:flutter/material.dart';

/// 컵 희귀도 정의
enum CupRarity {
  common, // 일반 (70%)
  uncommon, // 고급 (20%)
  rare, // 희귀 (7%)
  epic, // 에픽 (2.5%)
  legendary, // 전설 (0.5%)
}

/// 컵 희귀도 확장 메서드
extension CupRarityExtension on CupRarity {
  // 희귀도별 이름
  String get name {
    switch (this) {
      case CupRarity.common:
        return '일반';
      case CupRarity.uncommon:
        return '고급';
      case CupRarity.rare:
        return '희귀';
      case CupRarity.epic:
        return '에픽';
      case CupRarity.legendary:
        return '전설';
    }
  }

  // 희귀도별 색상
  Color get color {
    switch (this) {
      case CupRarity.common:
        return Colors.grey.shade400;
      case CupRarity.uncommon:
        return Colors.green.shade400;
      case CupRarity.rare:
        return Colors.blue.shade400;
      case CupRarity.epic:
        return Colors.purple.shade400;
      case CupRarity.legendary:
        return Colors.orange.shade400;
    }
  }

  // 획득 확률
  double get dropRate {
    switch (this) {
      case CupRarity.common:
        return 0.7; // 70%
      case CupRarity.uncommon:
        return 0.2; // 20%
      case CupRarity.rare:
        return 0.07; // 7%
      case CupRarity.epic:
        return 0.025; // 2.5%
      case CupRarity.legendary:
        return 0.005; // 0.5%
    }
  }
}

/// 컵 디자인 모델
class CupDesign {
  final String id; // 고유 식별자
  final String name; // 컵 이름
  final String description; // 컵 설명
  final String assetPath; // 디자인 이미지 경로
  final CupRarity rarity; // 희귀도
  final List<String> emotionTags; // 관련 감정 태그 (감정 ID)
  final String animationEffect; // 특수 애니메이션 효과 (선택적)
  final String unlockMessage; // 획득 시 메시지
  final Color mainColor; // 주 색상
  final List<String> tags; // 관련 태그 (감정, 테마 등)
  bool isUnlocked; // 획득 여부
  DateTime? obtainedAt; // 획득 시간

  CupDesign({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.rarity,
    required this.emotionTags,
    this.animationEffect = '',
    required this.unlockMessage,
    required this.mainColor,
    this.tags = const [],
    this.isUnlocked = false,
    this.obtainedAt,
  });

  // JSON에서 변환
  factory CupDesign.fromJson(Map<String, dynamic> json) {
    return CupDesign(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      assetPath: json['assetPath'] as String,
      rarity: CupRarity.values.firstWhere(
        (r) => r.toString() == 'CupRarity.${json['rarity']}',
        orElse: () => CupRarity.common,
      ),
      emotionTags: (json['emotionTags'] as List<dynamic>).cast<String>(),
      animationEffect: json['animationEffect'] as String? ?? '',
      unlockMessage: json['unlockMessage'] as String,
      mainColor: Color(json['mainColor']),
      tags: List<String>.from(json['tags']),
      isUnlocked: json['isUnlocked'] ?? false,
      obtainedAt:
          json['obtainedAt'] != null
              ? DateTime.parse(json['obtainedAt'])
              : null,
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'assetPath': assetPath,
      'rarity': rarity.toString().split('.').last,
      'emotionTags': emotionTags,
      'animationEffect': animationEffect,
      'unlockMessage': unlockMessage,
      'mainColor': mainColor.value,
      'tags': tags,
      'isUnlocked': isUnlocked,
      'obtainedAt': obtainedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupDesign && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  // 컵 잠금 해제
  void unlock() {
    if (!isUnlocked) {
      isUnlocked = true;
      obtainedAt = DateTime.now();
    }
  }
}

/// 사용자의 컵 컬렉션 아이템
class CollectionItem {
  final String id; // 고유 식별자
  final CupDesign cupDesign; // 컵 디자인
  final DateTime obtainedAt; // 획득 시간
  final int enhancementLevel; // 강화 레벨 (중복 획득 시 사용)

  CollectionItem({
    required this.id,
    required this.cupDesign,
    required this.obtainedAt,
    this.enhancementLevel = 0,
  });

  // 강화된 인스턴스 생성
  CollectionItem enhance() {
    return CollectionItem(
      id: id,
      cupDesign: cupDesign,
      obtainedAt: obtainedAt,
      enhancementLevel: enhancementLevel + 1,
    );
  }

  // JSON에서 변환
  factory CollectionItem.fromJson(
    Map<String, dynamic> json,
    Map<String, CupDesign> designsMap,
  ) {
    return CollectionItem(
      id: json['id'] as String,
      cupDesign: designsMap[json['cupDesignId']] ?? CupDesignsData.defaultCup,
      obtainedAt: DateTime.parse(json['obtainedAt'] as String),
      enhancementLevel: json['enhancementLevel'] as int? ?? 0,
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cupDesignId': cupDesign.id,
      'obtainedAt': obtainedAt.toIso8601String(),
      'enhancementLevel': enhancementLevel,
    };
  }
}

/// 스토리텔링 단계
class StoryStep {
  final String id; // 고유 식별자
  final String title; // 단계 제목
  final String content; // 내용
  final List<StoryChoice> choices; // 선택지 목록
  final String emotionTag; // 관련 감정 태그
  final double waterFillPercentage; // 물 채움 퍼센트 (0.0~1.0)
  final String backgroundMusic; // 배경 음악 경로
  final String animationEffect; // 애니메이션 효과

  StoryStep({
    required this.id,
    required this.title,
    required this.content,
    required this.choices,
    required this.emotionTag,
    required this.waterFillPercentage,
    this.backgroundMusic = '',
    this.animationEffect = '',
  });
}

/// 스토리 선택지
class StoryChoice {
  final String id; // 고유 식별자
  final String text; // 선택지 텍스트
  final String nextStepId; // 다음 스텝 ID
  final String emotionEffect; // 감정 효과 변화
  final double waterChange; // 물 채움 변화량

  StoryChoice({
    required this.id,
    required this.text,
    required this.nextStepId,
    required this.emotionEffect,
    required this.waterChange,
  });
}

/// 사용자 스토리 진행 상태
class StoryProgress {
  final String storyId; // 스토리 ID
  final String currentStepId; // 현재 단계 ID
  final List<String> visitedSteps; // 방문한 단계 ID 목록
  final double waterLevel; // 현재 물 채움 레벨 (0.0~1.0)
  final DateTime updatedAt; // 마지막 업데이트 시간

  StoryProgress({
    required this.storyId,
    required this.currentStepId,
    required this.visitedSteps,
    required this.waterLevel,
    required this.updatedAt,
  });
}

/// 사전 정의된 컵 디자인 데이터
class CupDesignsData {
  // 기본 컵 (획득 실패 시 사용)
  static final CupDesign defaultCup = CupDesign(
    id: 'default',
    name: '기본 컵',
    description: '가장 기본적인 디자인의 컵입니다.',
    assetPath: 'assets/images/cups/default_cup.png',
    rarity: CupRarity.common,
    emotionTags: ['calm'],
    unlockMessage: '기본 컵을 획득했습니다!',
    mainColor: Colors.grey,
    isUnlocked: true,
  );

  // 모든 컵 디자인 목록
  static List<CupDesign> allDesigns = [
    defaultCup,
    // 행복 관련 컵
    CupDesign(
      id: 'happy_day',
      name: '행복한 하루',
      description: '햇살처럼 밝고 따뜻한 기운이 담긴 컵입니다.',
      assetPath: 'assets/images/cups/happy_day_cup.png',
      rarity: CupRarity.common,
      emotionTags: ['joy', 'excitement'],
      unlockMessage: '행복한 하루 컵을 획득했습니다!',
      mainColor: Colors.amber,
      tags: ['joy', 'morning'],
    ),
    CupDesign(
      id: 'prosperity',
      name: '번영의 잔',
      description: '풍요와 성공의 기운이 담긴 화려한 컵입니다.',
      assetPath: 'assets/images/cups/prosperity_cup.png',
      rarity: CupRarity.epic,
      emotionTags: ['joy', 'excitement'],
      animationEffect: 'sparkle',
      unlockMessage: '축하합니다! 번영의 잔을 획득했습니다!',
      mainColor: Colors.deepOrange,
      tags: ['joy', 'celebration'],
    ),

    // 평온 관련 컵
    CupDesign(
      id: 'serene_blue',
      name: '고요한 파랑',
      description: '잔잔한 호수같은 평온함이 담긴 블루 컵입니다.',
      assetPath: 'assets/images/cups/serene_blue_cup.png',
      rarity: CupRarity.uncommon,
      emotionTags: ['calm'],
      unlockMessage: '고요한 파랑 컵을 획득했습니다!',
      mainColor: Colors.lightBlue,
      tags: ['calm', 'ocean'],
    ),

    // 슬픔 관련 컵
    CupDesign(
      id: 'gentle_rain',
      name: '부드러운 비',
      description: '서글픈 비가 내리는 날의 감성이 담긴 컵입니다.',
      assetPath: 'assets/images/cups/gentle_rain_cup.png',
      rarity: CupRarity.uncommon,
      emotionTags: ['sadness'],
      unlockMessage: '부드러운 비 컵을 획득했습니다!',
      mainColor: Colors.indigo.shade300,
      tags: ['sadness', 'rain'],
    ),

    // 분노 관련 컵
    CupDesign(
      id: 'volcanic',
      name: '화산의 분노',
      description: '불타오르는 화산같은 강렬한 에너지가 담긴 컵입니다.',
      assetPath: 'assets/images/cups/volcanic_cup.png',
      rarity: CupRarity.rare,
      emotionTags: ['anger'],
      animationEffect: 'flame',
      unlockMessage: '화산의 분노 컵을 획득했습니다!',
      mainColor: Colors.red,
      tags: ['anger', 'passion'],
    ),

    // 불안 관련 컵
    CupDesign(
      id: 'storm_chaser',
      name: '폭풍의 추적자',
      description: '불안과 혼란 속에서도 앞으로 나아가는 용기를 상징하는 컵입니다.',
      assetPath: 'assets/images/cups/storm_chaser_cup.png',
      rarity: CupRarity.rare,
      emotionTags: ['anxiety'],
      unlockMessage: '폭풍의 추적자 컵을 획득했습니다!',
      mainColor: Colors.deepOrange,
      tags: ['anxiety'],
    ),

    // 사랑 관련 컵
    CupDesign(
      id: 'heartful',
      name: '마음이 담긴 잔',
      description: '따뜻한 사랑과 애정이 담긴 하트 모양의 컵입니다.',
      assetPath: 'assets/images/cups/heartful_cup.png',
      rarity: CupRarity.uncommon,
      emotionTags: ['love'],
      unlockMessage: '마음이 담긴 잔을 획득했습니다!',
      mainColor: Colors.pink.shade200,
      tags: ['love', 'romantic'],
    ),

    // 전설급 컵
    CupDesign(
      id: 'celestial',
      name: '천상의 잔',
      description: '우주의 신비로운 에너지가 담긴 전설적인 컵입니다.',
      assetPath: 'assets/images/cups/celestial_cup.png',
      rarity: CupRarity.legendary,
      emotionTags: ['joy', 'calm', 'love'],
      animationEffect: 'cosmic',
      unlockMessage: '대단해요! 천상의 잔을 획득했습니다!',
      mainColor: Colors.purple,
      tags: ['legendary', 'dream', 'fantasy'],
    ),
  ];

  // 태그에 해당하는 컵 목록 필터링
  static List<CupDesign> filterByTag(String tag) {
    return allDesigns.where((cup) => cup.tags.contains(tag)).toList();
  }

  // 희귀도별 컵 필터링
  static List<CupDesign> getByRarity(CupRarity rarity) {
    return allDesigns.where((cup) => cup.rarity == rarity).toList();
  }
}
