import 'package:flutter/material.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'dart:math' as math;

/// 감정 컵을 시각화하는 위젯
class EmotionCupWidget extends StatefulWidget {
  final Emotion emotion;
  final Situation situation;

  const EmotionCupWidget({
    Key? key,
    required this.emotion,
    required this.situation,
  }) : super(key: key);

  @override
  State<EmotionCupWidget> createState() => _EmotionCupWidgetState();
}

class _EmotionCupWidgetState extends State<EmotionCupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _liquidAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 물결 애니메이션
    _liquidAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color cupColor =
        AppTheme.emotionColors[widget.emotion.colorName] ??
        AppTheme.primaryColor;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(250, 350),
            painter: EmotionCupPainter(
              color: cupColor,
              viscosity: widget.emotion.viscosity,
              pattern: widget.emotion.pattern,
              animationValue: _liquidAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

/// 감정 컵을 그리는 CustomPainter
class EmotionCupPainter extends CustomPainter {
  final Color color;
  final double viscosity;
  final String pattern;
  final double animationValue;

  EmotionCupPainter({
    required this.color,
    required this.viscosity,
    required this.pattern,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 컵 테두리 그리기
    _drawCupOutline(canvas, size);

    // 음료 내용물 그리기
    _drawLiquid(canvas, size);

    // 패턴 그리기
    _drawPattern(canvas, size);
  }

  void _drawCupOutline(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;

    // 컵 윤곽
    final cupPath =
        Path()
          ..moveTo(size.width * 0.2, size.height * 0.1)
          ..lineTo(size.width * 0.15, size.height * 0.9)
          ..lineTo(size.width * 0.85, size.height * 0.9)
          ..lineTo(size.width * 0.8, size.height * 0.1)
          ..close();

    // 그림자 효과
    canvas.drawShadow(cupPath, Colors.black.withOpacity(0.2), 10, true);

    // 컵 테두리 그리기
    canvas.drawPath(cupPath, paint);
  }

  void _drawLiquid(Canvas canvas, Size size) {
    final liquidPaint =
        Paint()
          ..color = color.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    // 음료 높이 (점도에 따라 변화, 0.0~1.0)
    final liquidHeight = size.height * 0.7 * (1 - viscosity * 0.3);
    final liquidTop = size.height * 0.9 - liquidHeight;

    // 상단 물결 효과
    final liquidPath = Path()..moveTo(size.width * 0.15, size.height * 0.9);

    // 점도가 낮을수록 물결이 더 움직임
    final waveHeight = (1.0 - viscosity) * 15.0;

    // 물결 그리기
    for (double i = size.width * 0.15; i <= size.width * 0.85; i += 5) {
      final waveY =
          liquidTop +
          math.sin((i / size.width) * 2 * math.pi + animationValue) *
              waveHeight;
      liquidPath.lineTo(i, waveY);
    }

    // 컵 하단 완성    liquidPath.lineTo(size.width * 0.85, size.height * 0.9);    liquidPath.close();    canvas.drawPath(liquidPath, liquidPaint);
  }

  void _drawPattern(Canvas canvas, Size size) {
    final patternPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    // 패턴에 따라 다른 시각화
    switch (pattern) {
      case 'bubble':
        _drawBubbles(canvas, size, patternPaint);
        break;
      case 'wave':
        _drawWaves(canvas, size, patternPaint);
        break;
      case 'dots':
        _drawDots(canvas, size, patternPaint);
        break;
      case 'lines':
        _drawLines(canvas, size, patternPaint);
        break;
      default:
        // 기본 패턴 없음
        break;
    }
  }

  void _drawBubbles(Canvas canvas, Size size, Paint paint) {
    final random = math.Random(42); // 고정된 시드로 일관된 랜덤 패턴

    // 점도가 낮을수록 거품이 많이 생김
    final bubbleCount = ((1.0 - viscosity) * 30).round() + 5;

    for (int i = 0; i < bubbleCount; i++) {
      final bubbleSize = random.nextDouble() * 10 + 3;
      final x = size.width * 0.15 + random.nextDouble() * (size.width * 0.7);
      final liquidHeight = size.height * 0.7 * (1 - viscosity * 0.3);
      final y = size.height * 0.9 - random.nextDouble() * liquidHeight;

      canvas.drawCircle(
        Offset(x, y + animationValue * (1.0 - viscosity) * 3),
        bubbleSize,
        paint,
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    final wavePath = Path();

    final liquidHeight = size.height * 0.7 * (1 - viscosity * 0.3);
    final liquidTop = size.height * 0.9 - liquidHeight;

    // 물결 높이
    final waveHeight = (1.0 - viscosity) * 8.0;
    final frequency = 0.15; // 주파수

    for (int i = 0; i < 3; i++) {
      final yOffset = liquidTop + liquidHeight * 0.3 * i;

      wavePath.moveTo(size.width * 0.15, yOffset);

      for (double x = size.width * 0.15; x <= size.width * 0.85; x += 2) {
        final normalizedX = (x - size.width * 0.15) / (size.width * 0.7);
        final y =
            yOffset +
            math.sin(
                  (normalizedX + animationValue * 0.05) *
                      2 *
                      math.pi *
                      frequency,
                ) *
                waveHeight;
        wavePath.lineTo(x, y);
      }
    }

    canvas.drawPath(wavePath, paint);
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    final random = math.Random(42);

    // 점도가 높을수록 점들이 더 밀집
    final dotFrequency = viscosity * 400 + 100;

    final liquidHeight = size.height * 0.7 * (1 - viscosity * 0.3);
    final liquidTop = size.height * 0.9 - liquidHeight;

    for (int i = 0; i < dotFrequency; i++) {
      final dotSize = random.nextDouble() * 2 + 1;
      final x = size.width * 0.15 + random.nextDouble() * (size.width * 0.7);
      final y = liquidTop + random.nextDouble() * liquidHeight;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    final liquidHeight = size.height * 0.7 * (1 - viscosity * 0.3);
    final liquidTop = size.height * 0.9 - liquidHeight;

    // 수직선 그리기
    for (double x = size.width * 0.2; x < size.width * 0.8; x += 10) {
      final lineHeight =
          (math.sin((x / size.width) * 4 * math.pi + animationValue) + 1) * 20 +
          10;

      canvas.drawLine(
        Offset(x, liquidTop + 10),
        Offset(x, liquidTop + lineHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EmotionCupPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.viscosity != viscosity ||
        oldDelegate.pattern != pattern ||
        oldDelegate.animationValue != animationValue;
  }
}
