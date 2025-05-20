import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/situation.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:cupsy/models/emotion_cup_model.dart';
import 'package:cupsy/utils/preferences_service.dart';
import 'package:cupsy/utils/daily_limit_manager.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// 감정 컵 상태 클래스
class CupState {
  final Emotion? selectedEmotion;
  final Situation? selectedSituation;
  final EmotionCupModel? generatedCup;
  final bool hasCreatedToday;
  final bool isLoading;
  final String? errorMessage;
  final int timeToNextCreation; // 다음 생성까지 남은 시간 (초)

  // 추가된 속성
  final CupDesign? cupDesign;
  final EmotionFlower? flower;
  final String? beverageName;
  final String? beverageDescription;

  CupState({
    this.selectedEmotion,
    this.selectedSituation,
    this.generatedCup,
    this.hasCreatedToday = false,
    this.isLoading = false,
    this.errorMessage,
    this.timeToNextCreation = 0,
    this.cupDesign,
    this.flower,
    this.beverageName,
    this.beverageDescription,
  });

  CupState copyWith({
    Emotion? selectedEmotion,
    Situation? selectedSituation,
    EmotionCupModel? generatedCup,
    bool? hasCreatedToday,
    bool? isLoading,
    String? errorMessage,
    int? timeToNextCreation,
    CupDesign? cupDesign,
    EmotionFlower? flower,
    String? beverageName,
    String? beverageDescription,
  }) {
    return CupState(
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      selectedSituation: selectedSituation ?? this.selectedSituation,
      generatedCup: generatedCup ?? this.generatedCup,
      hasCreatedToday: hasCreatedToday ?? this.hasCreatedToday,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      timeToNextCreation: timeToNextCreation ?? this.timeToNextCreation,
      cupDesign: cupDesign ?? this.cupDesign,
      flower: flower ?? this.flower,
      beverageName: beverageName ?? this.beverageName,
      beverageDescription: beverageDescription ?? this.beverageDescription,
    );
  }

  CupState clearError() {
    return CupState(
      selectedEmotion: selectedEmotion,
      selectedSituation: selectedSituation,
      generatedCup: generatedCup,
      hasCreatedToday: hasCreatedToday,
      isLoading: isLoading,
      errorMessage: null,
      timeToNextCreation: timeToNextCreation,
      cupDesign: cupDesign,
      flower: flower,
      beverageName: beverageName,
      beverageDescription: beverageDescription,
    );
  }
}

/// 감정 컵 생성 Notifier
class CupNotifier extends StateNotifier<CupState> {
  CupNotifier() : super(CupState()) {
    _checkIfCreatedToday();
  }

  /// 오늘 이미 컵을 생성했는지 확인
  Future<void> _checkIfCreatedToday() async {
    final canCreate = await DailyLimitManager.canCreateCupToday();
    final hasCreatedToday = !canCreate;

    int timeToNext = 0;
    if (hasCreatedToday) {
      timeToNext = await DailyLimitManager.getTimeToNextCreation();
    }

    state = state.copyWith(
      hasCreatedToday: hasCreatedToday,
      timeToNextCreation: timeToNext,
    );
  }

  /// 감정 선택
  void selectEmotion(Emotion emotion) {
    state = state.copyWith(selectedEmotion: emotion);
  }

  /// 상황 선택
  void selectSituation(Situation situation) {
    state = state.copyWith(selectedSituation: situation);
  }

  /// 감정 컵 생성
  Future<void> generateCup() async {
    try {
      if (state.selectedEmotion == null || state.selectedSituation == null) {
        state = state.copyWith(errorMessage: '감정과 상황을 모두 선택해주세요.');
        return;
      }

      // 일일 생성 제한 확인
      final canCreate = await DailyLimitManager.canCreateCupToday();
      if (!canCreate) {
        final timeToNext = await DailyLimitManager.getTimeToNextCreation();
        final formattedTime = DailyLimitManager.formatTimeRemaining(timeToNext);

        state = state.copyWith(
          errorMessage: '오늘은 이미 컵을 생성했습니다. $formattedTime.',
          hasCreatedToday: true,
          timeToNextCreation: timeToNext,
        );
        return;
      }

      state = state.copyWith(isLoading: true);

      // 랜덤 ID 생성 (실제로는 더 복잡한 방식으로 생성할 수 있음)
      final id = 'cup_${DateTime.now().millisecondsSinceEpoch}';

      // 감정과 상황에 따른 제목 생성
      final title = _generateTitle(
        state.selectedEmotion!,
        state.selectedSituation!,
      );

      // 감정과 상황에 따른 설명 생성
      final description = _generateDescription(
        state.selectedEmotion!,
        state.selectedSituation!,
      );

      // 감정에 맞는 컵 디자인 선택
      final cupDesign = await _selectCupDesign(state.selectedEmotion!.id);

      // 감정에 맞는 꽃 선택
      final flower = _selectEmotionFlower(state.selectedEmotion!.id);

      // 음료 이름과 설명 생성
      final beverageName = _generateBeverageName(
        state.selectedEmotion!,
        state.selectedSituation!,
        flower,
      );

      final beverageDescription = _generateBeverageDescription(
        state.selectedEmotion!,
        state.selectedSituation!,
        flower,
      );

      // 생성된 컵 객체 생성
      final cup = EmotionCupModel(
        id: id,
        emotion: state.selectedEmotion!,
        situation: state.selectedSituation!,
        createdAt: DateTime.now(),
        title: title,
        description: description,
        cupDesign: cupDesign,
        flower: flower,
      );

      // 일일 생성 제한 관리자에 기록
      await DailyLimitManager.recordCupCreation();

      // 마지막 생성 시간 저장 (기존 방식과의 호환성 유지)
      await PreferencesService.setLastCreatedDate(cup.createdAt);

      // 사용 횟수 증가
      await PreferencesService.incrementUsageCount();

      final timeToNext = await DailyLimitManager.getTimeToNextCreation();

      // 상태 업데이트
      state = state.copyWith(
        generatedCup: cup,
        hasCreatedToday: true,
        isLoading: false,
        timeToNextCreation: timeToNext,
        cupDesign: cupDesign,
        flower: flower,
        beverageName: beverageName,
        beverageDescription: beverageDescription,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '컵 생성 중 오류가 발생했습니다: $e',
        isLoading: false,
      );
    }
  }

  /// 제목 생성 함수
  String _generateTitle(Emotion emotion, Situation situation) {
    // 감정과 상황에 따른 제목 매핑
    final Map<String, Map<String, String>> titleMap = {
      'joy': {
        'work': '신나는 업무의 달콤한 한 모금',
        'social': '따뜻한 만남의 즐거움',
        'health': '건강한 기쁨의 순간',
        'home': '집에서 느끼는 행복',
        'leisure': '취미 속 즐거움',
        'travel': '여행지에서의 설렘',
        'financial': '풍요로움의 한 잔',
        'other': '기쁨이 가득한 오늘의 한 잔',
      },
      'calm': {
        'work': '차분한 업무의 멋진 진행',
        'social': '평온한 관계의 시간',
        'health': '건강한 마음의 평화',
        'home': '집에서의 고요한 휴식',
        'leisure': '여유로운 취미 시간',
        'travel': '여행지에서의 평화',
        'financial': '안정된 재정의 여유',
        'other': '평온함이 깃든 오늘의 한 잔',
      },
      // 다른 감정들에 대한 매핑도 추가
    };

    // 매핑된 제목 또는 기본 제목 반환
    return titleMap[emotion.id]?[situation.id] ??
        '${emotion.name}을(를) 담은 ${situation.name}의 한 잔';
  }

  /// 설명 생성 함수
  String _generateDescription(Emotion emotion, Situation situation) {
    return '${situation.name} 상황에서 느낀 ${emotion.name} 감정이 음료로 표현되었습니다. '
        '${emotion.description}이(가) ${situation.description}에서 느껴지는 특별한 순간을 담았습니다.';
  }

  /// 상태 초기화 (다음날 용)
  void resetState() {
    state = CupState();
    _checkIfCreatedToday();
  }

  /// 오류 메시지 지우기
  void clearError() {
    state = state.clearError();
  }

  /// 감정에 맞는 컵 디자인 선택
  Future<CupDesign?> _selectCupDesign(String emotionId) async {
    try {
      // CupDesignsData에서 이 감정에 맞는 모든 컵 디자인을 가져옴
      final List<CupDesign> availableDesigns = CupDesignsData.filterByTag(
        emotionId,
      );

      // 만약 사용 가능한 디자인이 없으면 null 반환
      if (availableDesigns.isEmpty) {
        return null;
      }

      // 가능한 컵 디자인 중 랜덤으로 선택
      final random = Random();
      return availableDesigns[random.nextInt(availableDesigns.length)];
    } catch (e) {
      // 에러 로깅
      print('컵 디자인 선택 중 오류: $e');
      return null;
    }
  }

  /// 감정에 맞는 꽃 선택
  EmotionFlower? _selectEmotionFlower(String emotionId) {
    try {
      // 감정에 맞는 꽃 찾기
      return EmotionFlowerData.findByEmotionId(emotionId);
    } catch (e) {
      // 에러 로깅
      print('꽃 선택 중 오류: $e');
      return null;
    }
  }

  /// 음료 이름 생성
  String _generateBeverageName(
    Emotion emotion,
    Situation situation,
    EmotionFlower? flower,
  ) {
    if (flower == null) {
      return '${emotion.name}의 특별한 한 잔';
    }

    final List<String> prefixes = [
      '향기로운',
      '달콤한',
      '상쾌한',
      '부드러운',
      '특별한',
      '감성적인',
      '은은한',
      '진한',
    ];

    final random = Random();
    final prefix = prefixes[random.nextInt(prefixes.length)];

    return '$prefix ${flower.name} ${emotion.name}';
  }

  /// 음료 설명 생성
  String _generateBeverageDescription(
    Emotion emotion,
    Situation situation,
    EmotionFlower? flower,
  ) {
    if (flower == null) {
      return '${emotion.name} 감정을 표현한 특별한 음료입니다.';
    }

    return '${emotion.name}을(를) 상징하는 ${flower.name} 꽃의 느낌을 담았습니다. '
        '${flower.flowerMeaning}의 의미를 가진 이 음료는 ${situation.name} 상황에서 '
        '당신의 감정을 위로합니다.';
  }
}

/// Provider 정의
final cupProvider = StateNotifierProvider<CupNotifier, CupState>((ref) {
  return CupNotifier();
});

/// 감정 목록 Provider
final emotionsProvider = Provider<List<Emotion>>((ref) {
  return EmotionData.emotions;
});

/// 상황 목록 Provider
final situationsProvider = Provider<List<Situation>>((ref) {
  return SituationData.situations;
});
