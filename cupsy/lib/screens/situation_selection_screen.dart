import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/providers/cup_provider.dart';

class SituationSelectionScreen extends ConsumerWidget {
  const SituationSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cupState = ref.watch(cupProvider);
    final situations = ref.watch(situationsProvider);

    // 선택된 감정이 없으면 감정 선택 화면으로 이동
    if (cupState.selectedEmotion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/emotion');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          '상황 선택',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 선택된 감정 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: emotionColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${cupState.selectedEmotion!.name} 감정',
                      style: TextStyle(
                        color: emotionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '어떤 상황에서 이런 감정을 느끼셨나요?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '상황에 따라 당신의 감정 음료가 달라질 수 있어요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: situations.length,
                  itemBuilder: (context, index) {
                    final situation = situations[index];
                    final isSelected =
                        cupState.selectedSituation?.id == situation.id;

                    return GestureDetector(
                      onTap: () {
                        // 상황 선택
                        ref
                            .read(cupProvider.notifier)
                            .selectSituation(situation);

                        // 다음 화면으로 이동 (결과 화면)
                        Navigator.of(context).pushNamed('/result');
                      },
                      child: Container(
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
                          border: Border.all(
                            color:
                                isSelected ? emotionColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _getSituationIcon(situation.icon, emotionColor),
                            const SizedBox(height: 8),
                            Text(
                              situation.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              situation.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상황에 따른 아이콘 반환
  Widget _getSituationIcon(String iconName, Color color) {
    IconData iconData;

    switch (iconName) {
      case 'work':
        iconData = Icons.work;
        break;
      case 'social':
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

    return Icon(iconData, color: color, size: 28);
  }
}
