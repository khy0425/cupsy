import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:cupsy/widgets/emotion_cup_widget.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cupState = ref.watch(cupProvider);

    // 감정과 상황이 선택되지 않은 경우 홈으로 이동
    if (cupState.selectedEmotion == null ||
        cupState.selectedSituation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
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

    // 감정에 해당하는 색상
    final emotionColor =
        AppTheme.emotionColors[cupState.selectedEmotion!.colorName] ??
        AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '나의 감정 음료',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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

              // 감정 컵 시각화
              Expanded(
                child: EmotionCupWidget(
                  emotion: cupState.selectedEmotion!,
                  situation: cupState.selectedSituation!,
                ),
              ),

              const SizedBox(height: 32),

              // 감정 및 상황 정보
              Container(
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

              const SizedBox(height: 24),

              // 공유 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareCup(context, cupState),
                      icon: const Icon(Icons.share),
                      label: const Text('공유하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        iconData = Icons.people;
        break;
      case 'health':
        iconData = Icons.favorite;
        break;
      case 'home':
        iconData = Icons.home;
        break;
      case 'leisure':
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
  void _shareCup(BuildContext context, CupState cupState) {
    // TODO: 실제로 이미지를 캡처하고 공유하는 로직 구현
    Share.share(
      '${cupState.generatedCup!.title}\n'
      '오늘의 감정: ${cupState.selectedEmotion!.name}\n'
      '상황: ${cupState.selectedSituation!.name}\n'
      '${cupState.generatedCup!.description}\n'
      'Cupsy 앱에서 만든 나만의 감정 음료입니다.',
    );
  }
}
