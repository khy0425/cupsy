import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cupsy/services/ad_service.dart';

/// 배너 광고를 표시하는 위젯
class AdBannerWidget extends ConsumerWidget {
  final AdSize adSize;

  /// 생성자
  const AdBannerWidget({Key? key, this.adSize = AdSize.banner})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAd = ref.watch(bannerAdProvider);

    return Container(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: bannerAd),
    );
  }
}

/// 결과 화면 하단에 표시될 배너 광고
class ResultScreenBannerAd extends ConsumerWidget {
  const ResultScreenBannerAd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: const AdBannerWidget(),
    );
  }
}
