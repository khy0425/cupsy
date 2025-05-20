import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

/// 광고 표시 도우미 클래스
class AdHelper {
  /// 전면 광고 표시
  static Future<void> showInterstitialAd(WidgetRef ref) async {
    final adState = ref.read(adStateProvider);

    if (adState.isInterstitialAdReady && adState.interstitialAd != null) {
      await adState.interstitialAd!.show();

      // 광고를 표시한 후 새 광고 로드
      ref.refresh(loadInterstitialAdProvider);
    } else {
      debugPrint('전면 광고가 준비되지 않았습니다.');

      // 광고 로드 시도
      ref.refresh(loadInterstitialAdProvider);
    }
  }

  /// 보상형 광고 표시
  static Future<bool> showRewardedAd(
    WidgetRef ref, {
    required Function(RewardItem reward) onRewarded,
  }) async {
    final adState = ref.read(adStateProvider);

    if (adState.isRewardedAdReady && adState.rewardedAd != null) {
      // 보상 콜백 등록
      adState.rewardedAd!.setImmersiveMode(true);
      await adState.rewardedAd!.show(
        onUserEarnedReward: (_, reward) => onRewarded(reward),
      );

      // 광고를 표시한 후 새 광고 로드
      ref.refresh(loadRewardedAdProvider);
      return true;
    } else {
      debugPrint('보상형 광고가 준비되지 않았습니다.');

      // 광고 로드 시도
      ref.refresh(loadRewardedAdProvider);
      return false;
    }
  }

  /// 앱 시작 시 광고 미리 로드
  static void preloadAds(WidgetRef ref) {
    ref.read(loadInterstitialAdProvider);
    ref.read(loadRewardedAdProvider);
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // 안드로이드 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('현재 플랫폼에서는 지원되지 않는 기능입니다.');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // 안드로이드 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // iOS 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('현재 플랫폼에서는 지원되지 않는 기능입니다.');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // 안드로이드 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      // iOS 테스트 광고 ID
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('현재 플랫폼에서는 지원되지 않는 기능입니다.');
    }
  }

  static bool isProduction = false;

  // 실제 광고 ID로 전환하는 메서드 (프로덕션 배포시 사용)
  static void setProductionAdUnitIds() {
    isProduction = true;
    // 프로덕션 광고 ID로 변경하는 로직 구현
    // 여기에 실제 광고 ID를 추가해야 함
  }
}
