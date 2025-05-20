import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/situation.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';

class SituationSelectionScreen extends ConsumerStatefulWidget {
  final String emotionId;

  const SituationSelectionScreen({Key? key, required this.emotionId})
    : super(key: key);

  @override
  ConsumerState<SituationSelectionScreen> createState() =>
      _SituationSelectionScreenState();
}

class _SituationSelectionScreenState
    extends ConsumerState<SituationSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _searchQuery;
  List<Situation> _filteredSituations = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();

    // 화면 방문 분석 이벤트 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'SituationSelection',
        screenClass: 'SituationSelectionScreen',
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterSituations(String query) {
    final situations = ref.read(situationsProvider);
    setState(() {
      _searchQuery = query;
      _filteredSituations =
          situations
              .where(
                (situation) =>
                    situation.name.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    situation.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cupState = ref.watch(cupProvider);
    final situations = ref.watch(situationsProvider);

    // 검색어가 없을 경우 전체 목록 사용
    final displaySituations =
        _searchQuery?.isNotEmpty == true ? _filteredSituations : situations;

    // 선택된 감정이 없으면 감정 선택 화면으로 이동
    if (cupState.selectedEmotion == null) {
      // emotionId가 제공된 경우, 해당 감정 선택
      if (widget.emotionId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // emotionId를 사용하여, 해당 감정 찾기
          final emotion = ref
              .read(emotionsProvider)
              .firstWhere(
                (e) => e.id == widget.emotionId,
                orElse: () => ref.read(emotionsProvider).first,
              );
          ref.read(cupProvider.notifier).selectEmotion(emotion);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.pushReplacementNamed('emotionSelection');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 선택된 감정 표시 - 애니메이션 적용
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.2, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        emotionColor.withOpacity(0.7),
                        emotionColor.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: emotionColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getEmotionIcon(cupState.selectedEmotion!.id),
                      const SizedBox(width: 8),
                      Text(
                        '${cupState.selectedEmotion!.name} 감정',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '어떤 상황에서 이런 감정을 느끼셨나요?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '상황에 따라 당신의 감정 음료가 달라질 수 있어요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 검색 필드
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: _filterSituations,
                      decoration: InputDecoration(
                        hintText: '상황 검색...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 상황 카드 목록
              Expanded(
                child:
                    displaySituations.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '검색 결과가 없습니다',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: displaySituations.length,
                          itemBuilder: (context, index) {
                            final situation = displaySituations[index];
                            final isSelected =
                                cupState.selectedSituation?.id == situation.id;

                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final delayedAnimation = CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    0.3 +
                                        (index / displaySituations.length) *
                                            0.5,
                                    0.3 +
                                        ((index + 1) /
                                                displaySituations.length) *
                                            0.5 +
                                        0.2,
                                    curve: Curves.easeOut,
                                  ),
                                );

                                return FadeTransition(
                                  opacity: delayedAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(delayedAnimation),
                                    child: child,
                                  ),
                                );
                              },
                              child: GestureDetector(
                                onTap: () {
                                  // 상황 선택
                                  ref
                                      .read(cupProvider.notifier)
                                      .selectSituation(situation);

                                  // 햅틱 피드백
                                  HapticFeedback.lightImpact();

                                  // 상황 선택 이벤트 로깅
                                  ErrorHandlingService.handleErrors(
                                    () => AnalyticsService.instance
                                        .logSituationSelected(
                                          situation.id,
                                          situation.name,
                                          cupState.selectedEmotion!.id,
                                        ),
                                    operationName:
                                        'situation_selection_tracking',
                                  );

                                  // 다음 화면으로 이동 (결과 화면)
                                  context.pushNamed(
                                    'result',
                                    queryParameters: {
                                      'emotionId': cupState.selectedEmotion!.id,
                                      'situationId': situation.id,
                                    },
                                  );
                                },
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 1.0,
                                    end: isSelected ? 1.1 : 1.0,
                                  ),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow:
                                              isSelected
                                                  ? [
                                                    BoxShadow(
                                                      color: emotionColor
                                                          .withOpacity(0.3),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        6,
                                                      ),
                                                    ),
                                                  ]
                                                  : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.06),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? emotionColor
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 상황 아이콘
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? emotionColor
                                                            .withOpacity(0.2)
                                                        : Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: _getSituationIcon(
                                                  situation.icon,
                                                  isSelected
                                                      ? emotionColor
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // 상황 이름
                                            Text(
                                              situation.name,
                                              style: TextStyle(
                                                color:
                                                    AppTheme.textPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // 상황 설명
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                situation.description,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      AppTheme
                                                          .textSecondaryColor,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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

    return Icon(iconData, color: color, size: 28);
  }

  // 각 감정에 맞는 아이콘 반환
  Widget _getEmotionIcon(String emotionId) {
    IconData iconData;

    switch (emotionId) {
      case 'joy':
        iconData = Icons.sentiment_very_satisfied;
        break;
      case 'calm':
        iconData = Icons.spa;
        break;
      case 'sadness':
        iconData = Icons.sentiment_dissatisfied;
        break;
      case 'anger':
        iconData = Icons.flash_on;
        break;
      case 'anxiety':
        iconData = Icons.storm;
        break;
      case 'love':
        iconData = Icons.favorite;
        break;
      case 'boredom':
        iconData = Icons.hourglass_empty;
        break;
      case 'excitement':
        iconData = Icons.celebration;
        break;
      default:
        iconData = Icons.emoji_emotions;
    }

    return Icon(iconData, color: Colors.white, size: 20);
  }
}
