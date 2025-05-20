import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/utils/preferences_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// 감정 컵 상태 클래스
class CupState {
  final Emotion? selectedEmotion;
  final Situation? selectedSituation;
  final EmotionCup? generatedCup;
  final bool hasCreatedToday;
  final bool isLoading;
  final String? errorMessage;

  CupState({
    this.selectedEmotion,
    this.selectedSituation,
    this.generatedCup,
    this.hasCreatedToday = false,
    this.isLoading = false,
    this.errorMessage,
  });

  CupState copyWith({
    Emotion? selectedEmotion,
    Situation? selectedSituation,
    EmotionCup? generatedCup,
    bool? hasCreatedToday,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CupState(
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      selectedSituation: selectedSituation ?? this.selectedSituation,
      generatedCup: generatedCup ?? this.generatedCup,
      hasCreatedToday: hasCreatedToday ?? this.hasCreatedToday,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
    state = state.copyWith(
      hasCreatedToday: PreferencesService.hasCreatedToday(),
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

      if (state.hasCreatedToday) {
        state = state.copyWith(errorMessage: '오늘은 이미 컵을 생성했습니다. 내일 다시 만들어보세요!');
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

      // 생성된 컵 객체 생성
      final cup = EmotionCup(
        id: id,
        emotion: state.selectedEmotion!,
        situation: state.selectedSituation!,
        createdAt: DateTime.now(),
        title: title,
        description: description,
      );

      // 마지막 생성 시간 저장
      await PreferencesService.setLastCreatedDate(cup.createdAt);

      // 사용 횟수 증가
      await PreferencesService.incrementUsageCount();

      // 상태 업데이트
      state = state.copyWith(
        generatedCup: cup,
        hasCreatedToday: true,
        isLoading: false,
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
