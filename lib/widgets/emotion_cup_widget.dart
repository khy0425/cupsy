import 'package:flutter/material.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/situation.dart' as sit;
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/utils/emotion_visualizer.dart';
import 'package:cupsy/utils/animation_helpers.dart';
import 'package:cupsy/utils/visual_properties.dart' as vp;
import 'dart:math' as math;

/// 감정 컵을 시각화하는 위젯
class EmotionCupWidget extends StatefulWidget {
  final Emotion emotion;
  final sit.Situation situation;

  const EmotionCupWidget({
    Key? key,
    required this.emotion,
    required this.situation,
  }) : super(key: key);

  @override
  State<EmotionCupWidget> createState() => _EmotionCupWidgetState();
}

class _EmotionCupWidgetState extends State<EmotionCupWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _transitionController;
  late AnimationController _entryController; // 화면 진입 애니메이션 컨트롤러
  late Map<String, Animation<double>> _animations;
  late vp.VisualProperties _visualProperties;
  late vp.VisualProperties _previousProperties;
  late Animation<vp.VisualProperties> _visualTransition;

  // 진입 애니메이션을 위한 변수들
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();

    // 시각적 속성 초기화
    _visualProperties = EmotionVisualizer.emotionToVisual(
      widget.emotion,
      widget.situation,
    );
    _previousProperties = _visualProperties;

    // 애니메이션 컨트롤러 초기화
    _mainController = AnimationHelpers.createEmotionAnimationController(
      vsync: this,
      emotion: widget.emotion,
    )..repeat(reverse: true);

    // 전환 애니메이션용 컨트롤러
    _transitionController = AnimationHelpers.createTransitionController(
      vsync: this,
    );

    // 진입 애니메이션 컨트롤러
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 진입 애니메이션 설정
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 진입 애니메이션 시작
    Future.microtask(() => _entryController.forward());

    // 애니메이션 생성
    _animations = AnimationHelpers.createEmotionAnimations(
      controller: _mainController,
      emotion: widget.emotion,
      situation: widget.situation,
      visualProperties: _visualProperties,
    );

    // 초기 전환 애니메이션 설정
    _visualTransition = AnimationHelpers.createVisualTransition(
      controller: _transitionController,
      begin: _visualProperties,
      end: _visualProperties,
    );
  }

  @override
  void didUpdateWidget(EmotionCupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 감정이나 상황이 변경되면 애니메이션 및 시각적 속성 업데이트
    if (oldWidget.emotion.id != widget.emotion.id ||
        oldWidget.situation.id != widget.situation.id) {
      // 이전 속성 저장
      _previousProperties = _visualProperties;

      // 새 속성 생성
      _visualProperties = EmotionVisualizer.emotionToVisual(
        widget.emotion,
        widget.situation,
      );

      // 메인 애니메이션 컨트롤러 재설정 (새 감정에 맞는 속도와 커브로)
      _mainController.dispose();
      _mainController = AnimationHelpers.createEmotionAnimationController(
        vsync: this,
        emotion: widget.emotion,
      )..repeat(reverse: true);

      // 애니메이션 업데이트
      _animations = AnimationHelpers.createEmotionAnimations(
        controller: _mainController,
        emotion: widget.emotion,
        situation: widget.situation,
        visualProperties: _visualProperties,
      );

      // 전환 애니메이션 설정 및 재생
      _visualTransition = AnimationHelpers.createVisualTransition(
        controller: _transitionController,
        begin: _previousProperties,
        end: _visualProperties,
      );

      _transitionController.forward(from: 0.0);

      // 새 감정/상황으로 변경 시 진입 애니메이션 다시 실행
      _entryController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _transitionController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _transitionController,
          _entryController,
        ]),
        builder: (context, child) {
          // 현재 사용할 시각적 속성 결정
          final currentProperties =
              _isFirstBuild || _transitionController.isDismissed
                  ? _visualProperties
                  : _visualTransition.value;

          if (_isFirstBuild) {
            _isFirstBuild = false;
          }

          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: CustomPaint(
                size: const Size(250, 350),
                painter: EmotionCupPainter(
                  visualProperties: currentProperties,
                  animations: _animations,
                  animationValue: _animations['wave']?.value ?? 0.0,
                  emotion: widget.emotion,
                  situation: widget.situation,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 감정 컵을 그리는 CustomPainter
class EmotionCupPainter extends CustomPainter {
  final vp.VisualProperties visualProperties;
  final Map<String, Animation<double>> animations;
  final double animationValue;
  final Emotion emotion;
  final sit.Situation situation;

  // 자주 사용되는 Paint 객체 캐싱
  late final Paint _highlightPaint;
  late final Paint _outlinePaint;
  late final Paint _innerPaint;
  late final Paint _liquidBaseCache;
  late final Paint _foamPaintCache;
  late final Paint _bubblePaintCache;

  EmotionCupPainter({
    required this.visualProperties,
    required this.animations,
    required this.animationValue,
    required this.emotion,
    required this.situation,
  }) {
    // 자주 사용되는 Paint 객체 미리 생성
    _highlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    _outlinePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    _innerPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.98)
          ..style = PaintingStyle.fill;

    _liquidBaseCache =
        Paint()
          ..color = visualProperties.color
          ..style = PaintingStyle.fill;

    _foamPaintCache =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    _bubblePaintCache =
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.fill;
  }

  // 컵 경로 캐싱 (호출 수 최소화)
  Path _getCupPath(Size size) {
    return EmotionVisualizer.getCupPath(visualProperties.cupStyle, size);
  }

  // 액체 상단 위치 계산 (호출 수 최소화)
  double _getLiquidTop(Size size) {
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();

    // 점도에 따른 액체 높이 계산 (점도가 높을수록 액체가 적게 채워짐)
    final liquidHeight =
        cupBounds.height * 0.9 * (1 - visualProperties.viscosity * 0.3);
    return cupBounds.bottom - liquidHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스 중앙을 기준으로 컵 위치 조정
    canvas.save();

    // 배경 그라데이션 (감정에 맞는 미묘한 배경 효과)
    _drawBackground(canvas, size);

    // 컵 그림자 그리기
    _drawCupShadow(canvas, size);

    // 컵 테두리 그리기
    _drawCupOutline(canvas, size);

    // 음료 내용물 그리기
    _drawLiquid(canvas, size);

    // 패턴 그리기
    _drawPattern(canvas, size);

    // 거품 그리기 (있는 경우)
    if (visualProperties.hasFoam) {
      _drawFoam(canvas, size);
    }

    // 컵 장식 (감정에 따른 특수 효과)
    _drawSpecialEffects(canvas, size);

    // 컵 핸들 그리기 (옵션)
    _drawCupHandle(canvas, size);

    // 하이라이트 및 반사 효과
    _drawHighlights(canvas, size);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size) {
    // 감정에 따른 미묘한 배경 그라데이션
    final bgPaint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              visualProperties.color.withOpacity(0.05),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }

  void _drawCupShadow(Canvas canvas, Size size) {
    // 컵 윤곽 - 그림자용
    final cupPath = _getCupPath(size);

    // 그림자 효과 - 더 부드럽고 현실적인 그림자
    canvas.drawShadow(cupPath, Colors.black.withOpacity(0.3), 15, true);
  }

  void _drawCupOutline(Canvas canvas, Size size) {
    // 컵 외부 테두리
    final outlinePaint = _outlinePaint;

    // 컵 내부 (흰색 배경)
    final innerPaint = _innerPaint;

    // 컵 경로 얻기
    final cupPath = _getCupPath(size);

    // 컵 내부 (흰색) 그리기
    canvas.drawPath(cupPath, innerPaint);

    // 컵 테두리 그리기
    canvas.drawPath(cupPath, outlinePaint);
  }

  void _drawLiquid(Canvas canvas, Size size) {
    // 컵 경로 얻기
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();
    final liquidTop = _getLiquidTop(size);

    // 액체 경로 생성 (컵 내부의 액체 영역)
    final Path liquidPath = Path();
    liquidPath.moveTo(cupBounds.left, cupBounds.bottom);
    liquidPath.lineTo(cupBounds.right, cupBounds.bottom);
    liquidPath.lineTo(cupBounds.right, liquidTop);

    // 물결 효과 애니메이션 (60fps에 최적화)
    final double waveHeight =
        visualProperties.viscosity < 0.3
            ? 5.0
            : (visualProperties.viscosity < 0.6 ? 3.0 : 1.5);

    final double waveWidth = cupBounds.width / 10;
    final double animOffset =
        animations.containsKey('wave')
            ? animations['wave']!.value
            : animationValue * 10;

    // 물결 최적화 - 점도에 따라 물결 복잡도 조정
    int wavePoints = visualProperties.viscosity < 0.5 ? 10 : 6;

    // 고성능 물결 효과
    for (int i = 0; i <= wavePoints; i++) {
      final double x = cupBounds.left + (i / wavePoints) * cupBounds.width;
      final double waveY = math.sin((x / waveWidth) + animOffset) * waveHeight;

      // 높은 점도일수록 물결이 작아짐
      final double viscosityEffect = 1.0 - visualProperties.viscosity * 0.7;
      final double y = liquidTop + waveY * viscosityEffect;

      if (i == 0) {
        liquidPath.lineTo(x, y);
      } else {
        liquidPath.lineTo(x, y);
      }
    }

    liquidPath.lineTo(cupBounds.left, liquidTop);
    liquidPath.close();

    // 액체 색상 설정 (캐시된 Paint 사용)
    _liquidBaseCache
      ..color = EmotionVisualizer.adjustColor(
        visualProperties.color,
        visualProperties.brightness,
        visualProperties.saturation,
      );

    // 클리핑으로 컵 밖으로 액체가 넘치지 않도록 함
    canvas.save();
    canvas.clipPath(cupPath);
    canvas.drawPath(liquidPath, _liquidBaseCache);
    canvas.restore();
  }

  void _drawPattern(Canvas canvas, Size size) {
    // 컵 경로 및 액체 상단 얻기
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();
    final liquidTop = _getLiquidTop(size);

    // 클리핑 영역 설정 (액체 내부만)
    final Path clipPath = Path();
    clipPath.addRect(
      Rect.fromLTRB(
        cupBounds.left,
        liquidTop,
        cupBounds.right,
        cupBounds.bottom,
      ),
    );

    canvas.save();
    canvas.clipPath(cupPath);
    canvas.clipPath(clipPath);

    // 패턴에 따라 다른 효과 적용 (성능 최적화)
    final patternPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final double density = visualProperties.patternDensity;
    final double patternSize = size.width * 0.05 * (1 + density);
    final double spacing = size.width * 0.15 * (1 - density * 0.5);

    switch (visualProperties.pattern) {
      case 'bubble':
        // 최적화된 버블 패턴 (랜덤성 감소)
        final int rows = (cupBounds.height / spacing).ceil();
        final int cols = (cupBounds.width / spacing).ceil();

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            // 고정된 옵셋으로 랜덤 효과 대체
            final double offsetX = (j % 2) * spacing * 0.5;
            final double offsetY = (i % 2) * spacing * 0.5;

            final double x = cupBounds.left + j * spacing + offsetX;
            final double y = liquidTop + i * spacing + offsetY;

            // 밀도 기반 그라데이션 효과 (상단에 더 많은 버블)
            final double opacityFactor = 1.0 - (i / rows);
            patternPaint.color = Colors.white.withOpacity(0.2 * opacityFactor);

            canvas.drawCircle(
              Offset(x, y),
              patternSize * (0.8 + (j % 3) * 0.1),
              patternPaint,
            );
          }
        }
        break;

      case 'wave':
        // 최적화된 웨이브 패턴
        final double waveHeight = size.height * 0.02 * density;
        final double waveWidth = size.width * 0.2;
        final int waves = 3;

        for (int wave = 0; wave < waves; wave++) {
          final Path wavePath = Path();
          final double startY =
              liquidTop +
              (cupBounds.height - liquidTop) * (wave + 1) / (waves + 1);

          wavePath.moveTo(cupBounds.left, startY);

          for (
            double x = cupBounds.left;
            x <= cupBounds.right;
            x += size.width * 0.05
          ) {
            final double y =
                startY +
                math.sin((x / waveWidth) + wave + animationValue * 2) *
                    waveHeight;
            wavePath.lineTo(x, y);
          }

          wavePath.lineTo(cupBounds.right, startY);
          patternPaint.style = PaintingStyle.stroke;
          patternPaint.strokeWidth = 2.0;
          canvas.drawPath(wavePath, patternPaint);
        }
        break;

      case 'dots':
        // 최적화된 점 패턴
        final int dots = (15 * density).toInt();
        final double maxRadius = patternSize * 1.5;
        final double minRadius = patternSize * 0.5;

        for (int i = 0; i < dots; i++) {
          // 고정 위치로 교체 (결정적 패턴)
          final double x =
              cupBounds.left + ((i * 37) % 100) / 100 * cupBounds.width;
          final double y =
              liquidTop +
              ((i * 53) % 100) / 100 * (cupBounds.bottom - liquidTop);
          final double radius =
              minRadius + ((i * 17) % 100) / 100 * (maxRadius - minRadius);

          patternPaint.color = Colors.white.withOpacity(
            0.1 + ((i * 13) % 10) / 30,
          );
          canvas.drawCircle(Offset(x, y), radius, patternPaint);
        }
        break;

      case 'lines':
        // 최적화된 선 패턴
        final int lineCount = (10 * density).toInt();
        patternPaint.strokeWidth = 2.0;
        patternPaint.style = PaintingStyle.stroke;

        for (int i = 0; i < lineCount; i++) {
          final double y =
              liquidTop +
              (cupBounds.bottom - liquidTop) * (i + 0.5) / lineCount;
          final double startX = cupBounds.left + cupBounds.width * 0.1;
          final double endX = cupBounds.right - cupBounds.width * 0.1;

          canvas.drawLine(Offset(startX, y), Offset(endX, y), patternPaint);
        }
        break;
    }

    canvas.restore();
  }

  void _drawFoam(Canvas canvas, Size size) {
    // 컵 경로 및 액체 상단 얻기
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();
    final liquidTop = _getLiquidTop(size);

    // 거품 영역 계산
    final double foamHeight =
        cupBounds.height * 0.15 * visualProperties.foamHeight;
    final double foamTop = liquidTop - foamHeight;

    // 거품 경로 생성
    final Path foamPath = Path();
    foamPath.moveTo(cupBounds.left, liquidTop);

    // 거품 상단 웨이브 생성
    final int divisions = 8;
    final double bubbleRadius = cupBounds.width * 0.05;

    // 거품 파동 애니메이션 (부드러운 움직임)
    final double foamAnim =
        animations.containsKey('foam')
            ? animations['foam']!.value
            : 1.0 + math.sin(animationValue * 2) * 0.1;

    // 거품 웨이브 최적화
    for (int i = 0; i <= divisions; i++) {
      final double t = i / divisions;
      final double x = cupBounds.left + t * cupBounds.width;
      final double bubbleOffset =
          (i % 2 == 0 ? -1 : 1) * bubbleRadius * foamAnim +
          math.sin(t * math.pi * 2 + animationValue * 3) * bubbleRadius * 0.5;

      foamPath.lineTo(x, foamTop + bubbleOffset);
    }

    foamPath.lineTo(cupBounds.right, liquidTop);
    foamPath.lineTo(cupBounds.left, liquidTop);
    foamPath.close();

    // 클리핑으로 컵 안에만 그리기
    canvas.save();
    canvas.clipPath(cupPath);
    canvas.drawPath(foamPath, _foamPaintCache);

    // 거품 방울 그리기 (성능 최적화 - 거품 수 제한)
    final int bubbleCount = (8 * visualProperties.foamHeight).ceil();

    for (int i = 0; i < bubbleCount; i++) {
      // 결정적 위치로 교체
      final double x =
          cupBounds.left + ((i * 37) % 100) / 100 * cupBounds.width;
      final double y = foamTop + ((i * 53) % 100) / 100 * foamHeight;
      final double radius = bubbleRadius * (0.3 + ((i * 17) % 10) / 10 * 0.7);

      canvas.drawCircle(Offset(x, y), radius * foamAnim, _bubblePaintCache);
    }

    canvas.restore();
  }

  void _drawSpecialEffects(Canvas canvas, Size size) {
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();
    final liquidTop = _getLiquidTop(size);

    // 감정별 특수 효과 (최적화 버전)
    for (String effect in visualProperties.specialEffects) {
      switch (effect) {
        case 'sparkle':
          _drawSparkleEffect(canvas, size, cupBounds, liquidTop);
          break;
        case 'glow':
          _drawGlowEffect(canvas, size, cupPath, cupBounds);
          break;
        case 'steam':
          _drawSteamEffect(canvas, size, cupBounds, liquidTop);
          break;
        case 'bubbles':
          _drawBubblingEffect(canvas, size, cupBounds, liquidTop);
          break;
        case 'fizz':
          _drawFizzEffect(canvas, size, cupBounds, liquidTop);
          break;
      }
    }
  }

  // 반짝임 효과 (기쁨, 행복 등의 감정)
  void _drawSparkleEffect(
    Canvas canvas,
    Size size,
    Rect cupBounds,
    double liquidTop,
  ) {
    final sparkleAnim =
        animations.containsKey('sparkle')
            ? animations['sparkle']!.value
            : animationValue;

    final int sparkleCount = 5;
    final Paint sparklePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    for (int i = 0; i < sparkleCount; i++) {
      // 결정적 위치로 교체
      final double progressOffset = (i / sparkleCount);
      final double progress = (sparkleAnim + progressOffset) % 1.0;

      // 액체 내부 랜덤 위치
      final double x =
          cupBounds.left + ((i * 37) % 100) / 100 * cupBounds.width;
      final double topOffset = cupBounds.height * 0.3;
      final double y =
          liquidTop +
          topOffset +
          progress * (cupBounds.bottom - liquidTop - topOffset);

      // 크기 변화 애니메이션
      final double baseSize = size.width * 0.02;
      final double sizeVar =
          baseSize * (0.5 + math.sin(progress * math.pi) * 0.5);

      // 투명도 변화 애니메이션
      sparklePaint.color = Colors.white.withOpacity((1.0 - progress) * 0.8);

      // 별 모양 그리기 (단순화된 버전)
      final Path starPath = Path();
      for (int j = 0; j < 5; j++) {
        final double angle = j * math.pi * 2 / 5 - math.pi / 2;
        final double length = j % 2 == 0 ? sizeVar : sizeVar * 0.5;
        final double starX = x + math.cos(angle) * length;
        final double starY = y + math.sin(angle) * length;

        if (j == 0) {
          starPath.moveTo(starX, starY);
        } else {
          starPath.lineTo(starX, starY);
        }
      }
      starPath.close();

      canvas.drawPath(starPath, sparklePaint);
    }
  }

  // 글로우 효과 (사랑, 신뢰 등의 감정)
  void _drawGlowEffect(Canvas canvas, Size size, Path cupPath, Rect cupBounds) {
    final glowAnim =
        animations.containsKey('glow')
            ? animations['glow']!.value
            : 0.5 + math.sin(animationValue * 2) * 0.5;

    // 컵 주변 글로우
    final Paint glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              visualProperties.color.withOpacity(0.3 * glowAnim),
              Colors.transparent,
            ],
            stops: const [0.5, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: cupBounds.center,
              width: cupBounds.width * 2,
              height: cupBounds.height * 2,
            ),
          );

    // 효율적인 글로우 렌더링
    canvas.saveLayer(cupBounds.inflate(size.width * 0.2), Paint());
    canvas.drawRect(cupBounds.inflate(size.width * 0.2), glowPaint);

    // 글로우에서 컵 모양 제외
    final Paint maskPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.dstOut;

    canvas.drawPath(cupPath, maskPaint);
    canvas.restore();
  }

  // 증기 효과 (분노, 열정, 뜨거운 음료 등)
  void _drawSteamEffect(
    Canvas canvas,
    Size size,
    Rect cupBounds,
    double liquidTop,
  ) {
    final steamAnim =
        animations.containsKey('steam')
            ? animations['steam']!.value
            : animationValue * 5;

    final int steamCount = 3;
    final Paint steamPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < steamCount; i++) {
      // 결정적 위치 (중앙에서 약간 좌우로 분산)
      final double centerOffset =
          (i - steamCount / 2) / steamCount * cupBounds.width * 0.6;
      final double x = cupBounds.center.dx + centerOffset;

      // 시간차 애니메이션 (연기가 순차적으로 올라가도록)
      final double progressOffset = i * 0.3;
      final double progress = (steamAnim + progressOffset) % 5.0;

      // 상승 애니메이션
      final double baseY = cupBounds.top - size.height * 0.1;
      final double y = baseY - progress * size.height * 0.1;

      // 크기 및 투명도 변화
      final double baseSize = cupBounds.width * 0.1;
      final double sizeMultiplier = math.min(1.0, progress * 0.5);
      final double opacity = math.max(0.0, 0.5 - progress * 0.1);

      steamPaint.color = Colors.white.withOpacity(opacity);

      // 증기 그리기
      canvas.drawCircle(Offset(x, y), baseSize * sizeMultiplier, steamPaint);
    }
  }

  // 거품 생성 효과 (놀람, 흥분 등의 감정)
  void _drawBubblingEffect(
    Canvas canvas,
    Size size,
    Rect cupBounds,
    double liquidTop,
  ) {
    final int bubbleCount = 8;
    final Paint bubblePaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withOpacity(0.6);

    for (int i = 0; i < bubbleCount; i++) {
      // 결정적 위치 + 시간 기반 애니메이션
      final double progressOffset = i / bubbleCount;
      final double progress = (animationValue * 2 + progressOffset) % 1.0;

      // 상승 경로
      final double pathOffset = ((i * 37) % 100) / 100 * cupBounds.width * 0.8;
      final double x = cupBounds.left + cupBounds.width * 0.1 + pathOffset;
      final double yStart = cupBounds.bottom - cupBounds.height * 0.1;
      final double yEnd = liquidTop;
      final double y = yStart + (yEnd - yStart) * progress;

      // 크기 변화 및 투명도
      final double size =
          cupBounds.width * 0.02 * (0.5 + math.sin(progress * math.pi) * 0.5);
      final double opacity = 0.8 - progress * 0.6;

      bubblePaint.color = Colors.white.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), size, bubblePaint);
    }
  }

  // 기포 효과 (놀람, 탄산 음료 등)
  void _drawFizzEffect(
    Canvas canvas,
    Size size,
    Rect cupBounds,
    double liquidTop,
  ) {
    final int fizzCount = 12;
    final Paint fizzPaint = Paint()..style = PaintingStyle.fill;

    // 컵 내부만 그리도록 클리핑
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        cupBounds.left,
        liquidTop,
        cupBounds.right,
        cupBounds.bottom,
      ),
    );

    for (int i = 0; i < fizzCount; i++) {
      // 결정적 위치 + 애니메이션
      final double progressOffset = i / fizzCount;
      final double progress = (animationValue * 3 + progressOffset) % 1.0;

      // 수평 위치는 고정, 수직 위치는 애니메이션
      final double x =
          cupBounds.left + ((i * 37) % 100) / 100 * cupBounds.width;
      final double yStart = cupBounds.bottom;
      final double yEnd = liquidTop;
      final double y = yStart - (yStart - yEnd) * progress;

      // 크기 및 투명도
      final double fizzSize = size.width * 0.01 * (0.5 + ((i * 17) % 10) / 10);
      final double opacity = 0.7 - progress * 0.5;

      fizzPaint.color = Colors.white.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), fizzSize, fizzPaint);
    }

    canvas.restore();
  }

  // 컵 핸들 그리기
  void _drawCupHandle(Canvas canvas, Size size) {
    if (visualProperties.cupStyle != 2) return; // 머그컵만 핸들 있음

    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();

    // 핸들 경로 생성
    final Path handlePath = Path();
    final double handleWidth = cupBounds.width * 0.15;
    final double handleHeight = cupBounds.height * 0.4;

    final double startX = cupBounds.right;
    final double startY = cupBounds.top + cupBounds.height * 0.3;
    final double endY = startY + handleHeight;

    handlePath.moveTo(startX, startY);
    handlePath.quadraticBezierTo(
      startX + handleWidth,
      startY + handleHeight * 0.5,
      startX,
      endY,
    );

    // 핸들 테두리 그리기
    canvas.drawPath(handlePath, _outlinePaint);

    // 핸들 내부 그리기
    canvas.drawPath(handlePath, _innerPaint);
  }

  void _drawHighlights(Canvas canvas, Size size) {
    // 컵 표면 하이라이트
    final highlightPaint = _highlightPaint;

    // 컵 경로 얻기
    final cupPath = _getCupPath(size);
    final cupBounds = cupPath.getBounds();

    // 상단 원형 하이라이트
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          cupBounds.left + cupBounds.width * 0.35,
          cupBounds.top + cupBounds.height * 0.25,
        ),
        width: cupBounds.width * 0.15,
        height: cupBounds.height * 0.05,
      ),
      highlightPaint,
    );

    // 액체 표면 하이라이트 (있는 경우)
    final liquidHeight =
        cupBounds.height * 0.9 * (1 - visualProperties.viscosity * 0.3);
    final liquidTop = cupBounds.bottom - liquidHeight;

    final liquidHighlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipPath(cupPath);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cupBounds.left + cupBounds.width * 0.4, liquidTop + 5),
        width: cupBounds.width * 0.3,
        height: 5,
      ),
      liquidHighlightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EmotionCupPainter oldDelegate) {
    // 최적화: 실제 변경된 경우에만 다시 그리기
    // 애니메이션 값이 변경된 경우 항상 다시 그려야 함
    if (animationValue != oldDelegate.animationValue) {
      return true;
    }

    // 감정이나 상황이 변경된 경우
    if (emotion.id != oldDelegate.emotion.id ||
        situation.id != oldDelegate.situation.id) {
      return true;
    }

    // 시각적 속성이 변경된 경우에만 다시 그리기
    return visualProperties != oldDelegate.visualProperties;
  }
}
