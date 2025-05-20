import 'package:flutter/material.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/services/gacha_service.dart';
import 'dart:math';

// 뽑기 상태
enum GachaState {
  ready, // 준비 상태
  drawing, // 뽑는 중
  result, // 결과 표시
}

/// 컵 뽑기 화면
class CupGachaScreen extends StatefulWidget {
  final bool useEmotionAdjustment; // 감정 기반 확률 조정 사용 여부
  final List<String>? emotionTags; // 감정 태그 (확률 조정에 사용)

  const CupGachaScreen({
    Key? key,
    this.useEmotionAdjustment = false,
    this.emotionTags,
  }) : super(key: key);

  @override
  _CupGachaScreenState createState() => _CupGachaScreenState();
}

class _CupGachaScreenState extends State<CupGachaScreen>
    with SingleTickerProviderStateMixin {
  // 서비스 객체
  final GachaService _gachaService = GachaService();

  // 기본 확률 분포 (GachaService의 _defaultRates가 private이므로 여기서 다시 정의)
  static const Map<CupRarity, double> _defaultRates = {
    CupRarity.common: 0.70, // 70%
    CupRarity.uncommon: 0.20, // 20%
    CupRarity.rare: 0.07, // 7%
    CupRarity.epic: 0.025, // 2.5%
    CupRarity.legendary: 0.005, // 0.5%
  };

  // 상태 변수
  GachaState _state = GachaState.ready;
  CupDesign? _resultCup;
  bool _isShaking = false;
  int _pityCounter = 0;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 피티 카운터 가져오기
    _pityCounter = _gachaService.failureCounter;

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 흔들림 애니메이션
    _shakeAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    // 크기 애니메이션
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // 애니메이션 상태 리스너
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 애니메이션 완료 시 결과 표시
        setState(() {
          _state = GachaState.result;
          _isShaking = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 뽑기 시작
  void _startDrawing() {
    setState(() {
      _state = GachaState.drawing;
      _isShaking = true;
    });

    // 감정 기반 확률 조정 적용
    Map<CupRarity, double>? customRates;
    if (widget.useEmotionAdjustment &&
        widget.emotionTags != null &&
        widget.emotionTags!.isNotEmpty) {
      customRates = _adjustRatesByEmotions(widget.emotionTags!);
    }

    // 뽑기 실행
    _resultCup = _gachaService.drawCup(
      CupDesignsData.allDesigns,
      customRates: customRates,
    );

    // 피티 카운터 업데이트
    _pityCounter = _gachaService.failureCounter;

    // 애니메이션 시작
    _animationController.forward(from: 0.0);
  }

  // 감정 기반 확률 조정
  Map<CupRarity, double> _adjustRatesByEmotions(List<String> emotions) {
    // 감정 태그를 가진 컵 찾기
    final taggedCups =
        emotions
            .expand((tag) => CupDesignsData.filterByTag(tag))
            .toSet() // 중복 제거
            .toList();

    // 태그된 컵이 없으면 기본 확률 유지
    if (taggedCups.isEmpty) {
      return Map.from(_defaultRates);
    }

    // 컵의 희귀도 분포 계산
    final Map<CupRarity, int> rarityCount = {};
    for (var cup in taggedCups) {
      rarityCount[cup.rarity] = (rarityCount[cup.rarity] ?? 0) + 1;
    }

    // 태그 관련 희귀도 가중치
    final adjustedRates = Map<CupRarity, double>.from(_defaultRates);

    // 태그된 희귀도의 확률 가중치 증가
    for (var entry in rarityCount.entries) {
      final boostFactor = entry.value * 0.1; // 같은 희귀도 컵이 많을수록 더 많이 올림
      adjustedRates[entry.key] =
          (adjustedRates[entry.key] ?? 0.0) * (1.0 + boostFactor);
    }

    // 총합이 1이 되도록 정규화
    final total = adjustedRates.values.fold(0.0, (sum, rate) => sum + rate);

    return adjustedRates.map((key, value) => MapEntry(key, value / total));
  }

  // 다시 뽑기
  void _reset() {
    setState(() {
      _state = GachaState.ready;
      _resultCup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('컵 뽑기'),
        actions: [
          if (_state == GachaState.ready)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '피티: $_pityCounter',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // 화면 본문
  Widget _buildBody() {
    switch (_state) {
      case GachaState.ready:
        return _buildReadyState();
      case GachaState.drawing:
        return _buildDrawingState();
      case GachaState.result:
        return _buildResultState();
    }
  }

  // 준비 상태 UI
  Widget _buildReadyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이미지
          Image.asset(
            'assets/images/gacha_machine.png',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.coffee, size: 100, color: Colors.grey[700]),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            '새로운 컵 뽑기',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.useEmotionAdjustment
                  ? '선택한 감정을 기반으로 컵을 뽑습니다!'
                  : '어떤 디자인의 컵이 나올까요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startDrawing,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('뽑기 시작', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 20),
          if (widget.useEmotionAdjustment && widget.emotionTags != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children:
                    widget.emotionTags!.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 뽑는 중 UI
  Widget _buildDrawingState() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 흔들리는 박스 애니메이션
              Transform.translate(
                offset: Offset(
                  15 * sin(_shakeAnimation.value * 10 * pi),
                  5 * cos(_shakeAnimation.value * 15 * pi),
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 80,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Text(
                _animationController.value < 0.8 ? '뽑는 중...' : '컵이 나타납니다!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      _animationController.value < 0.8
                          ? Colors.grey[700]
                          : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              if (_animationController.value < 0.8)
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _animationController.value / 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // 결과 표시 UI
  Widget _buildResultState() {
    if (_resultCup == null) {
      return const Center(child: Text('오류가 발생했습니다'));
    }

    final rarityColor = _resultCup!.rarity.color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 희귀도 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor),
            ),
            child: Text(
              _resultCup!.rarity.name,
              style: TextStyle(color: rarityColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          // 컵 이미지
          Hero(
            tag: 'cup_${_resultCup!.id}',
            child: Image.asset(
              _resultCup!.assetPath,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.local_cafe,
                    size: 100,
                    color: _resultCup!.mainColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          // 컵 이름
          Text(
            _resultCup!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 컵 설명
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _resultCup!.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
          // 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('다시 뽑기'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // 수집함으로 이동하는 코드 (나중에 구현)
                  Navigator.pop(context, _resultCup);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('수집함에 추가'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
