import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:flutter/material.dart';

/// 감정 칵테일 클래스 - 여러 감정의 조합으로 만들어지는 특별한 음료
class EmotionCocktail {
  final String id; // 고유 식별자
  final String name; // 칵테일 이름
  final String description; // 설명
  final List<Emotion> emotions; // 조합된 감정들
  final String imageUrl; // 칵테일 이미지 경로
  final Color cocktailColor; // 칵테일 색상
  final CupDesign specialCup; // 특별 컵 디자인
  final EmotionFlower? specialFlower; // 특별 꽃 (선택적)
  final String effectDescription; // 효과 설명
  final CupRarity rarity; // 희귀도
  final DateTime? createdAt; // 생성 시간
  bool isUnlocked; // 획득 여부

  EmotionCocktail({
    required this.id,
    required this.name,
    required this.description,
    required this.emotions,
    required this.imageUrl,
    required this.cocktailColor,
    required this.specialCup,
    this.specialFlower,
    required this.effectDescription,
    required this.rarity,
    this.createdAt,
    this.isUnlocked = false,
  });

  // JSON에서 변환
  factory EmotionCocktail.fromJson(
    Map<String, dynamic> json,
    List<Emotion> allEmotions,
    List<CupDesign> allCups,
    List<EmotionFlower> allFlowers,
  ) {
    // 감정 ID 리스트에서 감정 객체 찾기
    final emotionIds = (json['emotionIds'] as List<dynamic>).cast<String>();
    final emotions =
        emotionIds
            .map(
              (id) => allEmotions.firstWhere(
                (e) => e.id == id,
                orElse: () => EmotionData.emotions.first,
              ),
            )
            .toList();

    // 컵 ID로 컵 객체 찾기
    final cupId = json['specialCupId'] as String;
    final cup = allCups.firstWhere(
      (c) => c.id == cupId,
      orElse: () => CupDesignsData.allDesigns.first,
    );

    // 꽃 ID로 꽃 객체 찾기 (선택적)
    EmotionFlower? flower;
    if (json['specialFlowerId'] != null && allFlowers.isNotEmpty) {
      final flowerId = json['specialFlowerId'] as String;

      try {
        flower = allFlowers.firstWhere((f) => f.name == flowerId);
      } catch (e) {
        // 꽃을 찾지 못한 경우 첫 번째 꽃 사용 또는 null 유지
        flower = allFlowers.isNotEmpty ? allFlowers.first : null;
      }
    }

    return EmotionCocktail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emotions: emotions,
      imageUrl: json['imageUrl'] as String,
      cocktailColor: Color(json['cocktailColor'] as int),
      specialCup: cup,
      specialFlower: flower,
      effectDescription: json['effectDescription'] as String,
      rarity: CupRarity.values.firstWhere(
        (r) => r.toString() == 'CupRarity.${json['rarity']}',
        orElse: () => CupRarity.rare,
      ),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emotionIds': emotions.map((e) => e.id).toList(),
      'imageUrl': imageUrl,
      'cocktailColor': cocktailColor.value,
      'specialCupId': specialCup.id,
      'specialFlowerId': specialFlower?.name,
      'effectDescription': effectDescription,
      'rarity': rarity.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  // 오버라이드
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmotionCocktail && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  // 칵테일 획득
  void unlock() {
    if (!isUnlocked) {
      isUnlocked = true;
      specialCup.unlock();
    }
  }

  // 감정 칵테일 조합 문자열 생성
  String get emotionCombination {
    return emotions.map((e) => e.name).join(' + ');
  }
}

/// 미리 정의된 감정 칵테일 데이터
class EmotionCocktailData {
  // 미리 정의된 칵테일 목록 (실제로는 더 많은 조합이 있을 수 있음)
  static final List<EmotionCocktail> predefinedCocktails = [];

  // 초기화 함수 - 실제 앱에서는 모델이 로드된 후 호출
  static void initialize(
    List<Emotion> emotions,
    List<CupDesign> cupDesigns,
    List<EmotionFlower> flowers,
  ) {
    if (predefinedCocktails.isNotEmpty) return; // 이미 초기화됨

    // 몇 가지 특별한 조합 정의
    final joyEmotion = emotions.firstWhere(
      (e) => e.id == 'joy',
      orElse: () => EmotionData.emotions[0],
    );
    final loveEmotion = emotions.firstWhere(
      (e) => e.id == 'love',
      orElse: () => EmotionData.emotions[1],
    );
    final sadnessEmotion = emotions.firstWhere(
      (e) => e.id == 'sadness',
      orElse: () => EmotionData.emotions[2],
    );
    final trustEmotion = emotions.firstWhere(
      (e) => e.id == 'trust',
      orElse: () => EmotionData.emotions[3],
    );
    final angerEmotion = emotions.firstWhere(
      (e) => e.id == 'anger',
      orElse: () => EmotionData.emotions[4],
    );

    // 특별한 컵과 꽃 선택
    final epicCup = cupDesigns.firstWhere(
      (c) => c.rarity == CupRarity.epic,
      orElse: () => cupDesigns[0],
    );
    final legendaryCup = cupDesigns.firstWhere(
      (c) => c.rarity == CupRarity.legendary,
      orElse: () => cupDesigns[0],
    );

    // 꽃 선택 (있다면)
    EmotionFlower? loveFlower = flowers.isNotEmpty ? flowers[0] : null;

    // 예시: 기쁨 + 사랑 조합 (행복한 사랑 칵테일)
    predefinedCocktails.add(
      EmotionCocktail(
        id: 'cocktail_joy_love',
        name: '행복한 사랑 칵테일',
        description: '기쁨과 사랑이 조화롭게 어우러진 황금빛 칵테일입니다.',
        emotions: [joyEmotion, loveEmotion],
        imageUrl: 'assets/images/cocktails/joy_love_cocktail.png',
        cocktailColor: Color.fromARGB(255, 255, 192, 203), // 핑크빛 금색
        specialCup: epicCup,
        specialFlower: loveFlower,
        effectDescription: '당신의 마음에 행복한 사랑의 물결이 넘쳐흐릅니다.',
        rarity: CupRarity.epic,
        isUnlocked: false,
      ),
    );

    // 예시: 슬픔 + 분노 조합 (깊은 감정 칵테일)
    predefinedCocktails.add(
      EmotionCocktail(
        id: 'cocktail_sadness_anger',
        name: '깊은 감정의 폭풍 칵테일',
        description: '슬픔과 분노가 만나 일으키는 강렬한 감정의 소용돌이입니다.',
        emotions: [sadnessEmotion, angerEmotion],
        imageUrl: 'assets/images/cocktails/sadness_anger_cocktail.png',
        cocktailColor: Color.fromARGB(255, 128, 0, 128), // 진한 퍼플
        specialCup: epicCup,
        specialFlower: null,
        effectDescription: '억눌렸던 감정들을 해방시키고 깊은 치유를 경험합니다.',
        rarity: CupRarity.epic,
        isUnlocked: false,
      ),
    );

    // 예시: 기쁨 + 신뢰 + 사랑 조합 (전설의 조화 칵테일)
    predefinedCocktails.add(
      EmotionCocktail(
        id: 'cocktail_joy_trust_love',
        name: '완벽한 조화의 칵테일',
        description: '기쁨, 신뢰, 사랑이 완벽하게 균형을 이룬 황금빛 칵테일입니다.',
        emotions: [joyEmotion, trustEmotion, loveEmotion],
        imageUrl: 'assets/images/cocktails/harmony_cocktail.png',
        cocktailColor: Color.fromARGB(255, 255, 215, 0), // 황금색
        specialCup: legendaryCup,
        specialFlower: loveFlower,
        effectDescription: '마음 속 모든 감정이 조화롭게 어우러져 완벽한 평화를 선사합니다.',
        rarity: CupRarity.legendary,
        isUnlocked: false,
      ),
    );
  }

  /// 감정 조합으로 정의된 칵테일 찾기
  static EmotionCocktail? findByEmotions(List<Emotion> emotions) {
    if (emotions.isEmpty || predefinedCocktails.isEmpty) return null;

    // 감정 ID 집합
    final emotionIds = emotions.map((e) => e.id).toSet();

    // 감정 조합이 완전히 일치하는 칵테일 찾기
    for (final cocktail in predefinedCocktails) {
      final cocktailEmotionIds = cocktail.emotions.map((e) => e.id).toSet();

      // 감정 집합이 동일하면 반환
      if (setEquals(emotionIds, cocktailEmotionIds)) {
        return cocktail;
      }
    }

    return null;
  }

  /// 두 집합이 동일한지 확인
  static bool setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.containsAll(b);
  }
}

// 리스트 비교 헬퍼 함수
bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
