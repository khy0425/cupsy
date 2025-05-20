import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/emotion_cocktail_model.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'dart:math';

// 선택 모드 (단일 감정 또는 다중 감정 칵테일)
enum SelectionMode { single, cocktail }

class EmotionSelectionScreen extends ConsumerStatefulWidget {
  const EmotionSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmotionSelectionScreen> createState() =>
      _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends ConsumerState<EmotionSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _searchQuery;
  List<Emotion> _filteredEmotions = [];

  // 선택 모드 상태 추가
  SelectionMode _selectionMode = SelectionMode.single;

  // 다중 선택된 감정 목록
  List<Emotion> _selectedEmotions = [];

  // 감정 최대 선택 개수
  static const int _maxCocktailEmotions = 3;

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
      AnalyticsService.instance.logScreenView(screenName: 'EmotionSelection');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterEmotions(String query) {
    final emotions = ref.read(emotionsProvider);
    setState(() {
      _searchQuery = query;
      _filteredEmotions =
          emotions
              .where(
                (emotion) =>
                    emotion.name.toLowerCase().contains(query.toLowerCase()) ||
                    emotion.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  // 감정 선택 처리 (단일/다중 모드에 따라 다름)
  void _handleEmotionSelect(Emotion emotion) {
    if (_selectionMode == SelectionMode.single) {
      // 단일 감정 모드: 기존 로직대로 처리
      ref.read(cupProvider.notifier).selectEmotion(emotion);

      // 햅틱 피드백
      HapticFeedback.lightImpact();

      // 감정 선택 이벤트 로깅
      ErrorHandlingService.handleErrors(
        () => AnalyticsService.instance.logEmotionSelected(
          emotion.id,
          emotion.name,
        ),
        operationName: 'emotion_selection_tracking',
      );

      // 다음 화면으로 이동 (상황 선택)
      context.pushNamed(
        'situationSelection',
        queryParameters: {'emotionId': emotion.id},
      );
    } else {
      // 다중 감정 모드: 토글 형태로 처리
      setState(() {
        if (_selectedEmotions.contains(emotion)) {
          // 이미 선택된 감정이면 제거
          _selectedEmotions.remove(emotion);
        } else if (_selectedEmotions.length < _maxCocktailEmotions) {
          // 선택 안 된 감정이고 최대 선택 개수 미만이면 추가
          _selectedEmotions.add(emotion);

          // 햅틱 피드백
          HapticFeedback.lightImpact();
        } else {
          // 최대 선택 개수 초과 시 경고
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('최대 $_maxCocktailEmotions개의 감정만 선택할 수 있습니다'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  // 선택 모드 전환
  void _toggleSelectionMode() {
    setState(() {
      if (_selectionMode == SelectionMode.single) {
        _selectionMode = SelectionMode.cocktail;
        // 모드 변경 시 선택된 감정 초기화
        _selectedEmotions = [];
      } else {
        _selectionMode = SelectionMode.single;
        _selectedEmotions = [];
      }
    });

    // 햅틱 피드백
    HapticFeedback.mediumImpact();
  }

  // 감정 칵테일 생성 진행
  void _proceedWithCocktail() {
    if (_selectedEmotions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('하나 이상의 감정을 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 선택된 감정 IDs 문자열로 변환
    final emotionIds = _selectedEmotions.map((e) => e.id).join(',');

    // 칵테일 감정 선택 이벤트 로깅
    ErrorHandlingService.handleErrors(
      () => AnalyticsService.instance.logEmotionCocktailSelected(
        emotionIds,
        _selectedEmotions.map((e) => e.name).join('+'),
      ),
      operationName: 'emotion_cocktail_selection_tracking',
    );

    // 감정 칵테일 결과 화면으로 이동
    context.pushNamed(
      'emotionCocktailResult',
      queryParameters: {'emotionIds': emotionIds},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cupState = ref.watch(cupProvider);
    final emotions = ref.watch(emotionsProvider);

    // 검색어가 없을 경우 전체 목록 사용
    final displayEmotions =
        _searchQuery?.isNotEmpty == true ? _filteredEmotions : emotions;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectionMode == SelectionMode.single ? '오늘의 감정' : '감정 칵테일 만들기',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 모드 전환 버튼
          IconButton(
            icon: Icon(
              _selectionMode == SelectionMode.single
                  ? Icons.local_bar
                  : Icons.emoji_emotions,
              color: AppTheme.textPrimaryColor,
            ),
            tooltip:
                _selectionMode == SelectionMode.single
                    ? '감정 칵테일 모드로 전환'
                    : '단일 감정 모드로 전환',
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectionMode == SelectionMode.single
                    ? '지금 느끼는 감정을 선택해주세요'
                    : '칵테일에 넣을 감정들을 선택해주세요 (최대 $_maxCocktailEmotions개)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectionMode == SelectionMode.single
                    ? '당신의 감정을 음료로 표현해드릴게요'
                    : '여러 감정을 조합하여 특별한 칵테일을 만들어보세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),

              // 다중 선택 모드일 때 선택된 감정 표시 칩
              if (_selectionMode == SelectionMode.cocktail) ...[
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final emotion in _selectedEmotions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(emotion.name),
                            backgroundColor: emotion.color.withOpacity(0.3),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedEmotions.remove(emotion);
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 검색 필드
              Container(
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
                  onChanged: _filterEmotions,
                  decoration: InputDecoration(
                    hintText: '감정 검색...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 감정 카드 목록
              Expanded(
                child:
                    displayEmotions.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
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
                          itemCount: displayEmotions.length,
                          itemBuilder: (context, index) {
                            final emotion = displayEmotions[index];
                            final isSelected =
                                _selectionMode == SelectionMode.single
                                    ? cupState.selectedEmotion?.id == emotion.id
                                    : _selectedEmotions.contains(emotion);

                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final delayedAnimation = CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (index / displayEmotions.length) * 0.5,
                                    ((index + 1) / displayEmotions.length) *
                                            0.5 +
                                        0.5,
                                    curve: Curves.easeOut,
                                  ),
                                );

                                return FadeTransition(
                                  opacity: delayedAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(delayedAnimation),
                                    child: child,
                                  ),
                                );
                              },
                              child: GestureDetector(
                                onTap: () => _handleEmotionSelect(emotion),
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
                                          gradient: LinearGradient(
                                            colors: [
                                              emotion.color.withOpacity(0.7),
                                              emotion.color.withOpacity(0.4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: emotion.color.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: isSelected ? 8 : 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: emotion.color,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 다중 선택 모드에서 선택 표시자
                                              if (_selectionMode ==
                                                  SelectionMode.cocktail)
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          isSelected
                                                              ? emotion.color
                                                              : Colors.white
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child:
                                                        isSelected
                                                            ? const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            )
                                                            : null,
                                                  ),
                                                ),
                                              const Spacer(),
                                              Text(
                                                emotion.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(1, 1),
                                                      blurRadius: 2,
                                                      color: Color.fromARGB(
                                                        120,
                                                        0,
                                                        0,
                                                        0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                emotion.description,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 12,
                                                  shadows: const [
                                                    Shadow(
                                                      offset: Offset(1, 1),
                                                      blurRadius: 2,
                                                      color: Color.fromARGB(
                                                        120,
                                                        0,
                                                        0,
                                                        0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
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

      // 다중 선택 모드일 때만 하단에 계속 버튼 표시
      floatingActionButton:
          _selectionMode == SelectionMode.cocktail
              ? FloatingActionButton.extended(
                onPressed: _proceedWithCocktail,
                icon: const Icon(Icons.local_bar),
                label: const Text('감정 칵테일 만들기'),
                backgroundColor: AppTheme.primaryColor,
              )
              : null,
    );
  }
}
