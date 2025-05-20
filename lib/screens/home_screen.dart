import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:cupsy/widgets/app_scaffold.dart';
import 'package:cupsy/widgets/app_navigation_bar.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/utils/daily_limit_manager.dart';
import 'package:cupsy/widgets/ad_banner_widget.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 타이머 관련
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    // 남은 시간 업데이트
    _updateTimeRemaining();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateTimeRemaining() async {
    final cupState = ref.read(cupProvider);

    if (cupState.hasCreatedToday) {
      setState(() {
        _remainingSeconds = cupState.timeToNextCreation;
      });

      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        // 카운트다운이 끝났을 때, 상태 리셋
        ref.read(cupProvider.notifier).resetState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cupState = ref.watch(cupProvider);
    final bool canCreateToday = !cupState.hasCreatedToday;
    final String timeRemainingText =
        _remainingSeconds > 0
            ? DailyLimitManager.formatTimeRemaining(_remainingSeconds)
            : '';

    return AppScaffold(
      title: 'Cupsy',
      showBackButton: false, // 홈 화면에서는 뒤로가기 버튼 숨김
      actions: [
        // 앱 바 액션 버튼
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.textColor,
          ),
          onPressed: () {
            // 알림 기능 (향후 구현)
          },
        ),
      ],
      // 하단 네비게이션 바 추가
      bottomNavigationBar: const AppNavigationBar(currentIndex: 0),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 메인 앱 로고
                  const Icon(
                    Icons.local_cafe,
                    size: 120,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // 앱 이름 표시
                  const Text(
                    'Cupsy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 앱 설명
                  const Text(
                    '당신의 감정을 음료로 시각화해보세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 일일 생성 제한 정보 (생성 가능할 때는 표시 안 함)
                  if (!canCreateToday) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '오늘의 감정 음료를 이미 생성했어요',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeRemainingText,
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 감정 선택으로 이동하는 버튼
                  ElevatedButton(
                    onPressed:
                        canCreateToday
                            ? () => context.push(AppRoutes.emotionSelection)
                            : () {
                              // 이미 생성했을 때 메시지 표시
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '오늘은 이미 감정 음료를 생성했습니다. $timeRemainingText',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canCreateToday ? AppTheme.primaryColor : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 10),
                        const Text('감정 음료 만들기'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 컬렉션 화면으로 이동하는 버튼
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.collection),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      side: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections_bookmark,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text('내 컬렉션 보기'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 감정 통계 화면으로 이동하는 버튼
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.stats),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      side: const BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 2,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text('감정 통계 보기'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 배너 광고
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
