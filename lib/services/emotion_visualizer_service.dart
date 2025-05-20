import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:cupsy/models/emotion_cocktail_model.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:cupsy/services/data_repository.dart';

/// 감정 시각화 결과를 담는 클래스
class VisualizationResult {
  final CupDesign cupDesign;
  final EmotionFlower? flower;
  final String beverageName;
  final String beverageDescription;
  final Color beverageColor;
  final bool isSpecialCocktail;
  final EmotionCocktail? cocktail;
  final List<Emotion> emotions;

  VisualizationResult({
    required this.cupDesign,
    this.flower,
    required this.beverageName,
    required this.beverageDescription,
    required this.beverageColor,
    this.isSpecialCocktail = false,
    this.cocktail,
    required this.emotions,
  });
}

/// 감정 시각화 서비스 - 감정을 컵, 음료, 꽃 등으로 시각화
class EmotionVisualizerService {
  // 싱글톤 인스턴스
  static final EmotionVisualizerService _instance =
      EmotionVisualizerService._internal();
  static EmotionVisualizerService get instance => _instance;
  EmotionVisualizerService._internal();

  // 데이터 저장소 레퍼런스
  late EmotionRepository _emotionRepository;
  late CupDesignRepository _cupDesignRepository;
  late EmotionFlowerRepository _flowerRepository;

  // 결과 캐싱
  final Map<String, VisualizationResult> _singleEmotionCache = {};
  final Map<String, VisualizationResult> _cocktailCache = {};

  // 초기화 여부
  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 저장소 인스턴스 가져오기
      final repositoryFactory = RepositoryFactory();
      _emotionRepository = await repositoryFactory.getEmotionRepository();
      _cupDesignRepository = await repositoryFactory.getCupDesignRepository();
      _flowerRepository = await repositoryFactory.getEmotionFlowerRepository();

      _isInitialized = true;
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 시각화 서비스 초기화 실패',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 단일 감정 시각화
  Future<VisualizationResult> visualizeEmotion(Emotion emotion) async {
    if (!_isInitialized) await initialize();

    // 캐시된 결과가 있으면 반환
    if (_singleEmotionCache.containsKey(emotion.id)) {
      return _singleEmotionCache[emotion.id]!;
    }

    try {
      // 감정에 맞는 컵 디자인 가져오기
      final cupDesigns = await _cupDesignRepository.getCupDesignsByEmotion(
        emotion.id,
      );

      CupDesign selectedCup;
      if (cupDesigns.isNotEmpty) {
        // 해당 감정에 맞는 컵이 있다면 랜덤 선택
        selectedCup = cupDesigns[Random().nextInt(cupDesigns.length)];
      } else {
        // 없다면 전체에서 랜덤 선택
        final allDesigns = await _cupDesignRepository.getAllCupDesigns();
        selectedCup = allDesigns[Random().nextInt(allDesigns.length)];
      }

      // 감정에 맞는 꽃 가져오기
      final flowers = await _flowerRepository.getAllFlowers();
      final matchingFlowers =
          flowers.where((flower) => flower.emotion.id == emotion.id).toList();

      EmotionFlower? selectedFlower;
      if (matchingFlowers.isNotEmpty) {
        selectedFlower =
            matchingFlowers[Random().nextInt(matchingFlowers.length)];
      }

      // 음료 이름 생성
      final beverageName = _generateBeverageName(emotion);

      // 음료 설명 생성
      final beverageDescription = _generateBeverageDescription(emotion);

      // 결과 객체 생성
      final result = VisualizationResult(
        cupDesign: selectedCup,
        flower: selectedFlower,
        beverageName: beverageName,
        beverageDescription: beverageDescription,
        beverageColor: emotion.color,
        isSpecialCocktail: false,
        emotions: [emotion],
      );

      // 캐시에 저장
      _singleEmotionCache[emotion.id] = result;

      return result;
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 시각화 처리 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 다중 감정 시각화 (감정 칵테일)
  Future<VisualizationResult> createEmotionCocktail(
    List<Emotion> emotions,
  ) async {
    if (!_isInitialized) await initialize();

    // 감정이 없거나 하나라면 단일 감정 시각화
    if (emotions.isEmpty) {
      throw ArgumentError('감정이 선택되지 않았습니다.');
    }

    if (emotions.length == 1) {
      return visualizeEmotion(emotions.first);
    }

    // 감정들을 ID로 정렬하여 일관된 캐시 키 생성
    emotions.sort((a, b) => a.id.compareTo(b.id));
    final cacheKey = emotions.map((e) => e.id).join('_');

    // 캐시된 결과가 있으면 반환
    if (_cocktailCache.containsKey(cacheKey)) {
      return _cocktailCache[cacheKey]!;
    }

    try {
      // 컵 디자인, 꽃, 색상 등을 감정 조합에 맞게 생성

      // 1. 미리 정의된 칵테일인지 확인
      final predefinedCocktail = EmotionCocktailData.findByEmotions(emotions);

      if (predefinedCocktail != null) {
        // 미리 정의된 칵테일이 있으면 사용
        final result = VisualizationResult(
          cupDesign: predefinedCocktail.specialCup,
          flower: predefinedCocktail.specialFlower,
          beverageName: predefinedCocktail.name,
          beverageDescription: predefinedCocktail.description,
          beverageColor: predefinedCocktail.cocktailColor,
          isSpecialCocktail: true,
          cocktail: predefinedCocktail,
          emotions: emotions,
        );

        _cocktailCache[cacheKey] = result;
        return result;
      }

      // 2. 주된 감정 결정 (가장 처음 선택된 감정)
      final primaryEmotion = emotions.first;

      // 3. 색상 혼합
      final blendedColor = _blendColors(emotions.map((e) => e.color).toList());

      // 4. 희귀도 결정 (감정 개수에 따라)
      final rarity =
          emotions.length >= 3
              ? CupRarity.epic
              : (emotions.length == 2 ? CupRarity.rare : CupRarity.uncommon);

      // 5. 컵 선택
      final cupDesigns = await _cupDesignRepository.getAllCupDesigns();

      // 희귀도에 맞는 컵 필터링
      final rareCups = cupDesigns.where((cup) => cup.rarity == rarity).toList();

      CupDesign selectedCup;
      if (rareCups.isNotEmpty) {
        selectedCup = rareCups[Random().nextInt(rareCups.length)];
      } else {
        // 주된 감정에 맞는 컵 찾기
        final emotionCups =
            cupDesigns
                .where((cup) => cup.emotionTags.contains(primaryEmotion.id))
                .toList();

        if (emotionCups.isNotEmpty) {
          selectedCup = emotionCups[Random().nextInt(emotionCups.length)];
        } else {
          // 기본 선택
          selectedCup = cupDesigns.first;
        }
      }

      // 6. 꽃 선택 (랜덤)
      EmotionFlower? selectedFlower;
      if (Random().nextDouble() > 0.3) {
        // 70% 확률로 꽃 추가
        final flowers = await _flowerRepository.getAllFlowers();
        if (flowers.isNotEmpty) {
          // 감정 중 하나와 연관된 꽃 찾기
          final relatedFlowers =
              flowers
                  .where(
                    (flower) => emotions.any((e) => e.id == flower.emotion.id),
                  )
                  .toList();

          if (relatedFlowers.isNotEmpty) {
            selectedFlower =
                relatedFlowers[Random().nextInt(relatedFlowers.length)];
          } else {
            // 연관된 꽃이 없으면 랜덤 선택
            selectedFlower = flowers[Random().nextInt(flowers.length)];
          }
        }
      }

      // 7. 칵테일 이름 생성
      final cocktailName = '${emotions.map((e) => e.name).join(' & ')} 칵테일';

      // 8. 칵테일 설명 생성
      final emotionNames = emotions.map((e) => e.name).join('과(와) ');
      final cocktailDescription = '$emotionNames이(가) 조화롭게 어우러진 특별한 감정 칵테일입니다.';

      // 9. 컵 효과 설명
      final effectDescriptions = [
        '당신의 마음에 새로운 감정의 물결이 일렁입니다.',
        '복합적인 감정이 하나로 어우러져 새로운 경험을 선사합니다.',
        '서로 다른 감정이 만나 특별한 순간을 만들어냅니다.',
      ];
      final effectDescription =
          effectDescriptions[Random().nextInt(effectDescriptions.length)];

      // 10. 동적 칵테일 생성
      final cocktail = EmotionCocktail(
        id: 'cocktail_$cacheKey',
        name: cocktailName,
        description: cocktailDescription,
        emotions: emotions,
        imageUrl: 'assets/images/cocktails/cocktail_$cacheKey.png',
        cocktailColor: blendedColor,
        specialCup: selectedCup,
        specialFlower: selectedFlower,
        effectDescription: effectDescription,
        rarity: rarity,
        createdAt: DateTime.now(),
        isUnlocked: true,
      );

      // 11. 결과 생성
      final result = VisualizationResult(
        cupDesign: selectedCup,
        flower: selectedFlower,
        beverageName: cocktailName,
        beverageDescription: cocktailDescription,
        beverageColor: blendedColor,
        isSpecialCocktail: true,
        cocktail: cocktail,
        emotions: emotions,
      );

      // 캐시에 저장
      _cocktailCache[cacheKey] = result;

      return result;
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 칵테일 생성 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 여러 색상을 혼합하는 함수
  Color _blendColors(List<Color> colors) {
    if (colors.isEmpty) return Colors.transparent;
    if (colors.length == 1) return colors.first;

    int r = 0, g = 0, b = 0;
    for (var color in colors) {
      r += color.red;
      g += color.green;
      b += color.blue;
    }

    return Color.fromRGBO(
      r ~/ colors.length,
      g ~/ colors.length,
      b ~/ colors.length,
      1.0,
    );
  }

  /// 감정에 따른 음료 이름 생성
  String _generateBeverageName(Emotion emotion) {
    switch (emotion.id) {
      case 'joy':
        return '행복의 샘물';
      case 'sadness':
        return '고요한 푸른 차';
      case 'anger':
        return '붉은 열정의 펀치';
      case 'fear':
        return '떨리는 서리 주스';
      case 'surprise':
        return '놀라움의 스파클링 음료';
      case 'disgust':
        return '쓴 진실의 엘릭서';
      case 'anticipation':
        return '기대감 오렌지 네이드';
      case 'trust':
        return '신뢰의 청록색 포션';
      case 'love':
        return '로즈 물결 칵테일';
      case 'envy':
        return '에메랄드 인퓨전';
      default:
        // 감정이 목록에 없으면 이름 조합
        final adjectives = ['달콤한', '시원한', '상쾌한', '부드러운', '강렬한'];
        final names = ['물결', '음료', '차', '주스', '엘릭서'];
        return '${adjectives[Random().nextInt(adjectives.length)]} ${emotion.name} ${names[Random().nextInt(names.length)]}';
    }
  }

  /// 감정에 따른 음료 설명 생성
  String _generateBeverageDescription(Emotion emotion) {
    switch (emotion.id) {
      case 'joy':
        return '기쁨의 감정이 담긴 맑고 밝은 음료입니다. 마실 때마다 행복한 기억이 떠오릅니다.';
      case 'sadness':
        return '슬픔을 담은 깊고 고요한 푸른빛 음료입니다. 감정을 정화하는 효과가 있습니다.';
      case 'anger':
        return '강렬한 분노의 에너지가 담긴 붉은 음료입니다. 솔직한 감정 표현을 도와줍니다.';
      case 'fear':
        return '두려움의 떨림을 담은 서늘한 음료입니다. 두려움을 마주하는 용기를 줍니다.';
      case 'surprise':
        return '예상치 못한 놀라움처럼 톡톡 터지는 기포가 있는 음료입니다. 새로운 시각을 선사합니다.';
      case 'disgust':
        return '불쾌함과 거부감이 담긴 쓴맛의 음료입니다. 진실을 직시하는 힘을 줍니다.';
      case 'anticipation':
        return '기대감이 담긴 향긋한 오렌지색 음료입니다. 희망찬 미래를 그리게 합니다.';
      case 'trust':
        return '신뢰의 에너지가 담긴 깊고 맑은 청록색 음료입니다. 관계의 안정감을 더합니다.';
      case 'love':
        return '사랑의 감정이 담긴 로즈 빛 음료입니다. 따뜻한 마음이 전해집니다.';
      case 'envy':
        return '질투와 열망이 담긴 에메랄드 빛 음료입니다. 자기 성찰을 도와줍니다.';
      default:
        return '${emotion.name}의 감정이 담긴 특별한 음료입니다. 마음에 새로운 에너지를 선사합니다.';
    }
  }

  /// 캐시 비우기
  void clearCache() {
    _singleEmotionCache.clear();
    _cocktailCache.clear();
  }
}
