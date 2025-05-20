import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/emotion_cup_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:cupsy/widgets/cup_widget.dart';
import 'package:cupsy/widgets/animated_liquid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 감정 결과 화면 - 선택한 감정에 따른 컵/음료/꽃 표시
class EmotionResultScreen extends ConsumerStatefulWidget {
  const EmotionResultScreen({Key? key}) : super(key: key);

  @override
  _EmotionResultScreenState createState() => _EmotionResultScreenState();
}

class _EmotionResultScreenState extends ConsumerState<EmotionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isAnimating = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 화면 진입 기록
    AnalyticsService.instance.logScreenView(
      screenName: 'emotion_result_screen',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cupState = ref.watch(cupProvider);

    // 결과가 없으면 로딩 또는 오류 표시
    if (cupState.generatedCup == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child:
              cupState.isLoading
                  ? const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  )
                  : Text(
                    cupState.errorMessage ?? '결과를 불러올 수 없습니다',
                    style: const TextStyle(color: Colors.white),
                  ),
        ),
      );
    }

    // 결과 데이터 추출
    final cup = cupState.generatedCup!;
    final emotion = cup.emotion;
    final situation = cup.situation;
    final cupDesign = cupState.cupDesign;
    final flower = cupState.flower;
    final beverageName = cupState.beverageName ?? '감정의 한 잔';
    final beverageDescription =
        cupState.beverageDescription ?? '당신의 감정을 담은 특별한 음료입니다.';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _isSharing ? null : _shareResult,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: AppTheme.backgroundDark,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 타이틀 (음료 이름)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            beverageName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // 감정과 상황
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: emotion.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${emotion.name} × ${situation.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 컵과 음료 시각화
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 백그라운드 글로우 효과
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: emotion.color.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),

                            // 음료 애니메이션
                            SizedBox(
                              height: 220,
                              width: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 컵 디자인
                                  if (cupDesign != null)
                                    CupWidget(
                                      cupDesign: cupDesign,
                                      showGlow: true,
                                      scale: 1.2,
                                    )
                                  else
                                    // 기본 컵 모양
                                    Image.asset(
                                      'assets/images/cups/default_cup.png',
                                      height: 200,
                                    ),

                                  // 음료 애니메이션
                                  Positioned(
                                    top: 60,
                                    left: 20,
                                    right: 20,
                                    child: AnimatedLiquid(
                                      color: emotion.color,
                                      height: 80,
                                      animationController: _animationController,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // 음료 설명
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                beverageDescription,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),

                              if (flower != null) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: emotion.color.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_florist,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            flower.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '꽃말: ${flower.flowerMeaning}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 생성 정보
                        Text(
                          '${cup.createdAt.year}년 ${cup.createdAt.month}월 '
                          '${cup.createdAt.day}일 ${cup.createdAt.hour}시 '
                          '${cup.createdAt.minute}분 생성',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 하단 버튼 영역
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              name: 'create_new_cup_clicked',
                            );
                            // 상태 초기화 후 감정 선택 화면으로 이동
                            ref.read(cupProvider.notifier).resetState();
                            context.go('/emotions');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('새로운 감정 컵 만들기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 결과 공유하기
  Future<void> _shareResult() async {
    if (_isSharing) return;

    try {
      setState(() {
        _isSharing = true;
      });

      AnalyticsService.instance.logEvent(name: 'share_result_clicked');

      // 스크린샷 캡처
      final imageFile = await _screenshotController.capture();
      if (imageFile == null) {
        throw Exception('스크린샷 캡처에 실패했습니다');
      }

      // 임시 저장 경로
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/emotion_cup_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageFile);

      // 공유
      await Share.shareXFiles([
        XFile(filePath),
      ], text: '🍹 오늘의 감정 컵을 공유합니다! 당신만의 감정 음료를 만들어보세요!');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '결과 공유 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
