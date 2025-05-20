import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:cupsy/widgets/emotion_cup_widget.dart';
import 'package:cupsy/widgets/app_scaffold.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:cupsy/utils/image_utils.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cupsy/widgets/ad_banner_widget.dart';
import 'package:cupsy/utils/ad_helper.dart';
import 'package:cupsy/services/ad_service.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'dart:io';
import 'dart:typed_data';

class ResultScreen extends ConsumerStatefulWidget {
  final String emotionId;
  final String situationId;

  const ResultScreen({
    Key? key,
    required this.emotionId,
    required this.situationId,
  }) : super(key: key);

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  // 컵 애니메이션 컨트롤러
  late AnimationController _cupAnimationController;
  late Animation<double> _cupScaleAnimation;
  late Animation<double> _cupOpacityAnimation;
  late Animation<double> _infoCardAnimation;
  late Animation<double> _buttonsAnimation;

  // 스크린샷 컨트롤러
  final ScreenshotController _screenshotController = ScreenshotController();

  // 이미지 저장 상태
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _cupAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 스케일 애니메이션 설정
    _cupScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _cupAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 불투명도 애니메이션 설정
    _cupOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cupAnimationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 정보 카드 애니메이션
    _infoCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cupAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // 버튼 애니메이션
    _buttonsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cupAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // 화면 방문 로깅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'Result',
        screenClass: 'ResultScreen',
      );
    });

    // 컵이 생성된 후 애니메이션 시작
    Future.microtask(() {
      final cupState = ref.read(cupProvider);
      if (cupState.generatedCup != null) {
        _cupAnimationController.forward();

        // 컵 생성 이벤트 로깅
        if (widget.emotionId.isNotEmpty && widget.situationId.isNotEmpty) {
          ErrorHandlingService.handleErrors(
            () => AnalyticsService.instance.logCupGenerated(
              widget.emotionId,
              widget.situationId,
            ),
            operationName: 'cup_generation_tracking',
          );
        }

        // 전면 광고 로드 시도
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(loadInterstitialAdProvider);
        });
      }
    });
  }

  @override
  void dispose() {
    _cupAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cupState = ref.watch(cupProvider);

    // emotionId와 situationId가 제공된 경우, 해당 감정과 상황 선택
    if ((cupState.selectedEmotion == null ||
            cupState.selectedSituation == null) &&
        (widget.emotionId.isNotEmpty || widget.situationId.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // emotionId를 사용하여 해당 감정 찾기
        if (widget.emotionId.isNotEmpty && cupState.selectedEmotion == null) {
          final emotion = ref
              .read(emotionsProvider)
              .firstWhere(
                (e) => e.id == widget.emotionId,
                orElse: () => ref.read(emotionsProvider).first,
              );
          ref.read(cupProvider.notifier).selectEmotion(emotion);
        }

        // situationId를 사용하여 해당 상황 찾기
        if (widget.situationId.isNotEmpty &&
            cupState.selectedSituation == null) {
          final situation = ref
              .read(situationsProvider)
              .firstWhere(
                (s) => s.id == widget.situationId,
                orElse: () => ref.read(situationsProvider).first,
              );
          ref.read(cupProvider.notifier).selectSituation(situation);
        }
      });
    }

    // 감정과 상황이 선택되지 않은 경우 홈으로 이동
    if (cupState.selectedEmotion == null ||
        cupState.selectedSituation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 생성된 컵이 없으면 생성
    if (cupState.generatedCup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cupProvider.notifier).generateCup();
      });
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 24),
              Text(
                '당신의 감정 음료를 생성하고 있어요',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요...',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 컵 생성 후 애니메이션 시작
    if (!_cupAnimationController.isAnimating &&
        _cupAnimationController.isDismissed) {
      _cupAnimationController.forward();
    }

    // 감정에 해당하는 색상
    final emotionColor =
        AppTheme.emotionColors[cupState.selectedEmotion!.colorName] ??
        AppTheme.primaryColor;

    return AppScaffold(
      title: '나의 감정 음료',
      onBackPressed: () => context.go(AppRoutes.home),
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: _cupAnimationController,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 타이틀
              Text(
                cupState.generatedCup!.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: emotionColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 생성 날짜
              Text(
                _formatDate(cupState.generatedCup!.createdAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),

              // 감정 컵 시각화 (스크린샷 영역)
              Expanded(
                child: FadeTransition(
                  opacity: _cupOpacityAnimation,
                  child: ScaleTransition(
                    scale: _cupScaleAnimation,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Hero(
                        tag: 'emotionCup',
                        child: EmotionCupWidget(
                          emotion: cupState.selectedEmotion!,
                          situation: cupState.selectedSituation!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 감정 및 상황 정보
              FadeTransition(
                opacity: _infoCardAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(_infoCardAnimation),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: emotionColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '감정: ${cupState.selectedEmotion!.name}',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _getSituationIcon(cupState.selectedSituation!.icon),
                            const SizedBox(width: 8),
                            Text(
                              '상황: ${cupState.selectedSituation!.name}',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cupState.generatedCup!.description,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 액션 버튼들
              FadeTransition(
                opacity: _buttonsAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(_buttonsAnimation),
                  child: Row(
                    children: [
                      // 공유 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareCup(context, cupState),
                          icon: const Icon(Icons.share),
                          label: const Text('공유하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 저장 버튼
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 28,
                        child:
                            _isSaving
                                ? const CircularProgressIndicator()
                                : IconButton(
                                  onPressed:
                                      () => _saveImage(context, cupState),
                                  icon: Icon(
                                    Icons.save_alt,
                                    color: emotionColor,
                                  ),
                                  tooltip: '이미지 저장',
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // 배너 광고 추가
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: ResultScreenBannerAd(),
              ),
            ],
          );
        },
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 상황에 따른 아이콘 반환
  Widget _getSituationIcon(String iconName) {
    IconData iconData;

    switch (iconName) {
      case 'work':
        iconData = Icons.work;
        break;
      case 'social':
      case 'people':
      case 'relationship':
        iconData = Icons.people;
        break;
      case 'health':
        iconData = Icons.favorite;
        break;
      case 'home':
        iconData = Icons.home;
        break;
      case 'leisure':
      case 'hobby':
      case 'growth':
        iconData = Icons.sports_basketball;
        break;
      case 'travel':
        iconData = Icons.flight;
        break;
      case 'financial':
        iconData = Icons.attach_money;
        break;
      case 'other':
      default:
        iconData = Icons.more_horiz;
        break;
    }

    return Icon(iconData, color: AppTheme.textPrimaryColor, size: 20);
  }

  // 컵 공유 함수
  Future<void> _shareCup(BuildContext context, CupState cupState) async {
    try {
      setState(() => _isSaving = true);

      // 광고 표시 (비동기로 처리하여 이미지 캡처 지연 방지)
      Future.microtask(() => AdHelper.showInterstitialAd(ref));

      // 이미지 캡쳐
      final Uint8List? imageBytes = await ImageUtils.captureScreenshotWidget(
        _screenshotController,
      );

      if (imageBytes == null) {
        _showErrorSnackBar(context, '이미지를 캡쳐하는데 실패했습니다.');
        setState(() => _isSaving = false);
        return;
      }

      // 임시 파일 저장
      final String fileName =
          'cupsy_${DateTime.now().millisecondsSinceEpoch}.png';
      final File? tempFile = await ImageUtils.saveTempFile(
        imageBytes,
        fileName,
      );

      if (tempFile == null) {
        _showErrorSnackBar(context, '이미지 파일을 생성하는데 실패했습니다.');
        setState(() => _isSaving = false);
        return;
      }

      // 공유 텍스트
      final String shareText =
          '${cupState.generatedCup!.title}\n'
          '오늘의 감정: ${cupState.selectedEmotion!.name}\n'
          '상황: ${cupState.selectedSituation!.name}\n'
          '${cupState.generatedCup!.description}\n'
          'Cupsy 앱에서 만든 나만의 감정 음료입니다.';

      // 공유
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: shareText,
        subject: cupState.generatedCup!.title,
      );

      // 공유 이벤트 로깅
      ErrorHandlingService.handleErrors(
        () => AnalyticsService.instance.logShare('cup_image', 'share_sheet'),
        operationName: 'share_tracking',
      );
    } catch (e, stackTrace) {
      // 오류 로깅
      ErrorHandlingService.logError(
        '이미지 공유 실패',
        error: e,
        stackTrace: stackTrace,
      );

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandlingService.getUserFriendlyErrorMessage(e)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 이미지 저장 함수
  Future<void> _saveImage(BuildContext context, CupState cupState) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final imageBytes = await ImageUtils.captureScreenshotWidget(
        _screenshotController,
      );
      if (imageBytes != null) {
        // 이미지 저장
        final imagePath = await ImageUtils.saveImageToGallery(imageBytes);

        // 이미지 저장 이벤트 로깅
        ErrorHandlingService.handleErrors(
          () => AnalyticsService.instance.logEvent(
            name: 'cup_image_saved',
            parameters: {
              'emotion_id': widget.emotionId,
              'situation_id': widget.situationId,
            },
          ),
          operationName: 'image_save_tracking',
        );

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다.')));
        }
      }
    } catch (e, stackTrace) {
      // 오류 로깅
      ErrorHandlingService.logError(
        '이미지 저장 실패',
        error: e,
        stackTrace: stackTrace,
      );

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandlingService.getUserFriendlyErrorMessage(e)),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 오류 메시지 스낵바
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
