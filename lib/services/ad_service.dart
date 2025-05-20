import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// AdMob 광고 서비스 클래스
class AdService {
  // 테스트 광고 ID (개발 단계에서 사용)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // 실제 광고 ID (출시 전 변경 필요)
  static const String _productionBannerAdUnitId = '';
  static const String _productionInterstitialAdUnitId = '';
  static const String _productionRewardedAdUnitId = '';

  // 테스트 디바이스 ID (필요한 경우 추가)
  static const List<String> _testDeviceIds = [];

  // 현재 환경에 맞는 광고 ID 반환
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    return _productionBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    return _productionInterstitialAdUnitId;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }
    return _productionRewardedAdUnitId;
  }

  // AdMob 초기화
  static Future<InitializationStatus> initialize() {
    return MobileAds.instance.initialize();
  }

  // 배너 광고 로드
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => debugPrint('배너 광고 로드 완료'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('배너 광고 로드 실패: $error');
        },
      ),
    );
  }

  // 전면 광고 로드
  static Future<InterstitialAd?> loadInterstitialAd() async {
    final completer = Completer<InterstitialAd?>();

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('전면 광고 표시 실패: $error');
            },
          );
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('전면 광고 로드 실패: $error');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  // 보상형 광고 로드
  static Future<RewardedAd?> loadRewardedAd() async {
    final completer = Completer<RewardedAd?>();

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('보상형 광고 표시 실패: $error');
            },
          );
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('보상형 광고 로드 실패: $error');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }
}

// 배너 광고 Provider
final bannerAdProvider = Provider<BannerAd>((ref) {
  final bannerAd = AdService.createBannerAd();
  bannerAd.load();
  ref.onDispose(() {
    bannerAd.dispose();
  });
  return bannerAd;
});

// 광고 상태 Provider
final adStateProvider = StateProvider<AdState>((ref) => AdState());

// 광고 상태 클래스
class AdState {
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;
  bool isInterstitialAdReady = false;
  bool isRewardedAdReady = false;

  // 메모리 관리를 위한 광고 해제
  void dispose() {
    interstitialAd?.dispose();
    rewardedAd?.dispose();
    interstitialAd = null;
    rewardedAd = null;
    isInterstitialAdReady = false;
    isRewardedAdReady = false;
  }
}

// 전면 광고 로드 Provider
final loadInterstitialAdProvider = FutureProvider<bool>((ref) async {
  final adState = ref.watch(adStateProvider.notifier);

  // 기존 광고가 있으면 해제
  adState.state.interstitialAd?.dispose();

  final interstitialAd = await AdService.loadInterstitialAd();
  if (interstitialAd != null) {
    adState.state =
        AdState()
          ..interstitialAd = interstitialAd
          ..isInterstitialAdReady = true
          ..rewardedAd = adState.state.rewardedAd
          ..isRewardedAdReady = adState.state.isRewardedAdReady;
    return true;
  }

  adState.state =
      AdState()
        ..isInterstitialAdReady = false
        ..rewardedAd = adState.state.rewardedAd
        ..isRewardedAdReady = adState.state.isRewardedAdReady;
  return false;
});

// 보상형 광고 로드 Provider
final loadRewardedAdProvider = FutureProvider<bool>((ref) async {
  final adState = ref.watch(adStateProvider.notifier);

  // 기존 광고가 있으면 해제
  adState.state.rewardedAd?.dispose();

  final rewardedAd = await AdService.loadRewardedAd();
  if (rewardedAd != null) {
    adState.state =
        AdState()
          ..rewardedAd = rewardedAd
          ..isRewardedAdReady = true
          ..interstitialAd = adState.state.interstitialAd
          ..isInterstitialAdReady = adState.state.isInterstitialAdReady;
    return true;
  }

  adState.state =
      AdState()
        ..isRewardedAdReady = false
        ..interstitialAd = adState.state.interstitialAd
        ..isInterstitialAdReady = adState.state.isInterstitialAdReady;
  return false;
});
