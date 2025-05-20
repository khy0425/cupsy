import 'dart:math';
import 'package:cupsy/models/cup_collection_model.dart';

/// 컵 뽑기 시스템 서비스
class GachaService {
  // 실패 카운터 (피티 시스템)
  int _failureCounter = 0;

  // 확률 분포 (기본값)
  static const Map<CupRarity, double> _defaultRates = {
    CupRarity.common: 0.70, // 70%
    CupRarity.uncommon: 0.20, // 20%
    CupRarity.rare: 0.07, // 7%
    CupRarity.epic: 0.025, // 2.5%
    CupRarity.legendary: 0.005, // 0.5%
  };

  // 피티 시스템 기준 실패 횟수
  static const int _legendaryPityThreshold = 100; // 100번 실패하면 전설 컵 확정
  static const int _epicPityThreshold = 50; // 50번 실패하면 에픽 이상 확정
  static const int _rarePityThreshold = 20; // 20번 실패하면 레어 이상 확정

  // 무작위 객체
  final Random _random = Random();

  // 싱글톤 패턴
  static final GachaService _instance = GachaService._internal();

  factory GachaService() {
    return _instance;
  }

  GachaService._internal();

  /// 컵 뽑기 실행
  ///
  /// 확률 기반으로 컵의 희귀도를 결정하고, 해당 희귀도에 맞는 컵을 반환합니다.
  /// 피티 시스템이 적용되어 연속 실패 시 점차 높은 등급의 컵을 얻을 확률이 올라갑니다.
  ///
  /// [cupPool] - 뽑기 대상 컵 목록 (희귀도별로 분류되어야 함)
  /// [customRates] - 커스텀 확률 설정 (기본값 사용 시 null)
  ///
  /// 반환값: 선택된 컵 디자인
  CupDesign drawCup(
    List<CupDesign> cupPool, {
    Map<CupRarity, double>? customRates,
  }) {
    // 확률 분포 결정
    final rates = customRates ?? _defaultRates;

    // 피티 시스템 적용된 희귀도 결정
    final rarity = _determineRarityWithPity(rates);

    // 해당 희귀도의 컵 필터링
    final cupsOfRarity = cupPool.where((cup) => cup.rarity == rarity).toList();

    // 해당 희귀도의 컵이 없으면 기본 컵 반환
    if (cupsOfRarity.isEmpty) {
      // 실패 카운터 초기화 (성공으로 간주)
      if (rarity == CupRarity.epic || rarity == CupRarity.legendary) {
        _failureCounter = 0;
      }
      return CupDesignsData.defaultCup;
    }

    // 랜덤하게 하나 선택
    final selectedCup = cupsOfRarity[_random.nextInt(cupsOfRarity.length)];

    // 에픽 또는 전설 뽑으면 실패 카운터 초기화
    if (rarity == CupRarity.epic || rarity == CupRarity.legendary) {
      _failureCounter = 0;
    } else {
      // 그 외는 실패 카운터 증가
      _failureCounter++;
    }

    return selectedCup;
  }

  /// 피티 시스템이 적용된 희귀도 결정
  CupRarity _determineRarityWithPity(Map<CupRarity, double> rates) {
    // 피티 시스템 적용
    if (_failureCounter >= _legendaryPityThreshold) {
      return CupRarity.legendary; // 100번 이상 실패하면 전설 확정
    } else if (_failureCounter >= _epicPityThreshold) {
      // 50번 이상 실패하면 에픽 또는 전설만 가능
      final rand = _random.nextDouble();
      final legendaryRate = rates[CupRarity.legendary]!;
      final epicRate = rates[CupRarity.epic]!;
      final normalizedLegendaryRate =
          legendaryRate / (legendaryRate + epicRate);

      return rand < normalizedLegendaryRate
          ? CupRarity.legendary
          : CupRarity.epic;
    } else if (_failureCounter >= _rarePityThreshold) {
      // 20번 이상 실패하면 레어 이상만 가능
      final rand = _random.nextDouble();
      final legendaryRate = rates[CupRarity.legendary]!;
      final epicRate = rates[CupRarity.epic]!;
      final rareRate = rates[CupRarity.rare]!;
      final totalRate = legendaryRate + epicRate + rareRate;

      final normalizedLegendaryRate = legendaryRate / totalRate;
      final normalizedEpicRate = epicRate / totalRate;

      if (rand < normalizedLegendaryRate) {
        return CupRarity.legendary;
      } else if (rand < normalizedLegendaryRate + normalizedEpicRate) {
        return CupRarity.epic;
      } else {
        return CupRarity.rare;
      }
    }

    // 일반 확률 적용
    final rand = _random.nextDouble();
    double cumulativeRate = 0.0;

    for (final entry in rates.entries) {
      cumulativeRate += entry.value;
      if (rand <= cumulativeRate) {
        return entry.key;
      }
    }

    // 기본값 반환 (확률 합이 1보다 작은 경우에 대비)
    return CupRarity.common;
  }

  /// 현재 실패 카운터 (테스트 및 디버그용)
  int get failureCounter => _failureCounter;

  /// 실패 카운터 수동 설정 (테스트용)
  set failureCounter(int value) {
    _failureCounter = value;
  }

  /// 실패 카운터 리셋
  void resetFailureCounter() {
    _failureCounter = 0;
  }
}
