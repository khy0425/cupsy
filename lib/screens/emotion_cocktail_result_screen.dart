import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/emotion_cocktail_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/providers/cup_provider.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:cupsy/services/data_repository.dart';
import 'package:cupsy/widgets/animated_liquid.dart';
import 'package:cupsy/widgets/cup_widget.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// 감정 칵테일 결과 화면 - 여러 감정을 조합해 특별한 칵테일을 만들어 보여주는 화면
class EmotionCocktailResultScreen extends ConsumerStatefulWidget {
  final String emotionIds; // 쉼표로 구분된 감정 ID 목록

  const EmotionCocktailResultScreen({Key? key, required this.emotionIds})
    : super(key: key);

  @override
  ConsumerState<EmotionCocktailResultScreen> createState() =>
      _EmotionCocktailResultScreenState();
}

class _EmotionCocktailResultScreenState
    extends ConsumerState<EmotionCocktailResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  bool _isLoading = true;
  EmotionCocktail? _cocktail;
  List<Emotion> _selectedEmotions = [];
  String _errorMessage = '';
  bool _showFlower = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // 화면 로딩 시 데이터 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCocktail();

      // 화면 방문 분석 이벤트 기록
      AnalyticsService.instance.logScreenView(
        screenName: 'EmotionCocktailResult',
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // 칵테일 데이터 로드
  Future<void> _loadCocktail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 감정 ID 목록 추출
      final emotionIds = widget.emotionIds.split(',');

      if (emotionIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '선택된 감정이 없습니다.';
        });
        return;
      }

      // 감정 객체 로드
      final emotionRepository =
          await RepositoryFactory().getEmotionRepository();
      final emotions = await emotionRepository.getAllEmotions();

      // 선택된 감정들 필터링
      _selectedEmotions =
          emotions.where((emotion) => emotionIds.contains(emotion.id)).toList();

      if (_selectedEmotions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '선택된 감정을 찾을 수 없습니다.';
        });
        return;
      }

      // 컵 디자인 가져오기
      final cupDesignRepository =
          await RepositoryFactory().getCupDesignRepository();
      final cupDesigns = await cupDesignRepository.getAllCupDesigns();

      // 꽃 데이터 가져오기
      final flowerRepository =
          await RepositoryFactory().getEmotionFlowerRepository();
      final flowers = await flowerRepository.getAllFlowers();

      // 미리 정의된 감정 조합 검색
      EmotionCocktail? predefinedCocktail = EmotionCocktailData.findByEmotions(
        _selectedEmotions,
      );

      if (predefinedCocktail != null) {
        // 미리 정의된 조합이 있으면 사용
        _cocktail = predefinedCocktail;
      } else {
        // 없으면 동적으로 칵테일 생성
        _cocktail = _generateDynamicCocktail(
          _selectedEmotions,
          cupDesigns,
          flowers,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // 애니메이션 시작
      _startAnimations();
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '칵테일 결과 로드 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = '칵테일을 만드는 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 동적으로 칵테일 생성
  EmotionCocktail _generateDynamicCocktail(
    List<Emotion> emotions,
    List<CupDesign> cupDesigns,
    List<EmotionFlower> flowers,
  ) {
    // 감정들의 색상 혼합
    final blendedColor = _blendColors(emotions.map((e) => e.color).toList());

    // 희귀도 결정 (감정 개수에 따라)
    final rarity =
        emotions.length >= 3
            ? CupRarity.epic
            : (emotions.length == 2 ? CupRarity.rare : CupRarity.uncommon);

    // 이름 생성
    final cocktailName = '${emotions.map((e) => e.name).join(' & ')} 칵테일';

    // 독특한 ID 생성
    final emotionIds = emotions.map((e) => e.id).join('_');
    final id = 'cocktail_$emotionIds';

    // 설명 생성
    final description =
        '${emotions.map((e) => e.name).join('과(와) ')}이(가) '
        '조화롭게 어우러진 특별한 감정 칵테일입니다.';

    // 효과 설명
    final effects = <String>[
      '당신의 마음에 새로운 감정의 물결이 일렁입니다.',
      '복합적인 감정이 하나로 어우러져 새로운 경험을 선사합니다.',
      '서로 다른 감정이 만나 특별한 순간을 만들어냅니다.',
    ];
    final effectDescription = effects[Random().nextInt(effects.length)];

    // 컵 선택 - 감정 중 가장 강한 감정의 컵 또는 랜덤한 특별한 컵
    final dominantEmotion = emotions.first; // 첫 번째 감정을 기본으로 사용
    final specialCups =
        cupDesigns.where((cup) => cup.rarity == rarity).toList();

    CupDesign specialCup;
    if (specialCups.isNotEmpty) {
      specialCup = specialCups[Random().nextInt(specialCups.length)];
    } else {
      // 해당 희귀도의 컵이 없으면, 감정에 맞는 컵 선택
      final dominantEmotionCups =
          cupDesigns
              .where((cup) => cup.emotionTags.contains(dominantEmotion.id))
              .toList();

      if (dominantEmotionCups.isNotEmpty) {
        specialCup =
            dominantEmotionCups[Random().nextInt(dominantEmotionCups.length)];
      } else {
        // 기본 컵 사용
        specialCup = cupDesigns.first;
      }
    }

    // 꽃 선택 - 감정 중 하나의 꽃 또는 null
    EmotionFlower? specialFlower;
    if (flowers.isNotEmpty && Random().nextDouble() > 0.3) {
      // 70% 확률로 꽃 추가
      final randomEmotion = emotions[Random().nextInt(emotions.length)];
      specialFlower = flowers.firstWhere(
        (flower) => flower.emotion.id == randomEmotion.id,
        orElse: () => flowers[Random().nextInt(flowers.length)],
      );
    }

    return EmotionCocktail(
      id: id,
      name: cocktailName,
      description: description,
      emotions: emotions,
      imageUrl: 'assets/images/cocktails/$id.png', // 실제로는 이미지 없을 수 있음
      cocktailColor: blendedColor,
      specialCup: specialCup,
      specialFlower: specialFlower,
      effectDescription: effectDescription,
      rarity: rarity,
      createdAt: DateTime.now(),
      isUnlocked: true, // 바로 획득
    );
  }

  // 여러 색상을 혼합하는 함수
  Color _blendColors(List<Color> colors) {
    if (colors.isEmpty) return Colors.transparent;
    if (colors.length == 1) return colors.first;

    int r = 0, g = 0, b = 0;
    for (var color in colors) {
      r += color.red;
      g += color.green;
      b += color.blue;
    }

    return Color.fromRGBO(
      r ~/ colors.length,
      g ~/ colors.length,
      b ~/ colors.length,
      1.0,
    );
  }

  // 애니메이션 시작
  void _startAnimations() {
    // 컵 채우기 애니메이션
    _animationController.forward();

    // 0.8초 후 축하 효과 시작
    Future.delayed(const Duration(milliseconds: 800), () {
      _confettiController.play();

      // 햅틱 피드백
      HapticFeedback.mediumImpact();
    });

    // 꽃 표시 애니메이션 (칵테일에 꽃이 있는 경우)
    if (_cocktail?.specialFlower != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          _showFlower = true;
        });

        // 햅틱 피드백
        HapticFeedback.lightImpact();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '감정 칵테일',
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
      body: Stack(
        children: [
          // 배경 효과 (페이드인)
          AnimatedOpacity(
            opacity: !_isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.backgroundColor,
                    _cocktail?.cocktailColor.withOpacity(0.1) ??
                        AppTheme.backgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 축하 효과
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // 아래쪽 방향
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.2,
              colors: _selectedEmotions.map((e) => e.color).toList(),
            ),
          ),

          if (_isLoading)
            // 로딩 화면
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '감정들을 조합하는 중...',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage.isNotEmpty)
            // 오류 화면
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            )
          else
            // 결과 화면
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 결과 제목
                    Text(
                      _cocktail?.name ?? '감정 칵테일',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // 감정 조합 표시
                    Text(
                      _cocktail?.emotionCombination ?? '',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 희귀도 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _rarityText(_cocktail?.rarity),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 컵 및 리퀴드 애니메이션
                    SizedBox(
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 컵 이미지
                          CupWidget(
                            cupDesign: _cocktail?.specialCup,
                            scale: 1.4,
                          ),

                          // 리퀴드 애니메이션
                          Positioned(
                            top: 50,
                            child: AnimatedLiquid(
                              animation: _animationController,
                              color: _cocktail?.cocktailColor ?? Colors.blue,
                              height: 200,
                              width: 100,
                            ),
                          ),

                          // 꽃 이미지 (있는 경우)
                          if (_cocktail?.specialFlower != null)
                            AnimatedOpacity(
                              opacity: _showFlower ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 600),
                              child: Positioned(
                                top: 30,
                                right: 70,
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Image.asset(
                                    _cocktail!.specialFlower!.imageUrl,
                                    width: 60,
                                    height: 60,
                                    errorBuilder:
                                        (_, __, ___) => const SizedBox(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 설명
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '칵테일 설명',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cocktail?.description ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '효과',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cocktail?.effectDescription ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 꽃말 카드 (꽃이 있는 경우)
                    if (_cocktail?.specialFlower != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: _cocktail!.specialFlower!.emotion.color
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _cocktail!.specialFlower!.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.local_florist,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_cocktail!.specialFlower!.name} (꽃말)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        _cocktail!.specialFlower!.flowerMeaning,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '당신의 복합적인 감정에 어울리는 꽃과 꽃말이 담겨있습니다.',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // 버튼
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('다시 만들기'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.pushNamed('collection');
                            },
                            icon: const Icon(Icons.collections_bookmark),
                            label: const Text('컬렉션 보기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 희귀도 텍스트 변환
  String _rarityText(CupRarity? rarity) {
    switch (rarity) {
      case CupRarity.common:
        return '일반';
      case CupRarity.uncommon:
        return '희귀';
      case CupRarity.rare:
        return '레어';
      case CupRarity.epic:
        return '에픽';
      case CupRarity.legendary:
        return '전설';
      default:
        return '알 수 없음';
    }
  }
}
