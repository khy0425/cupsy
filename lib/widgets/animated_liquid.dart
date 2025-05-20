import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 유체 채우기 애니메이션 위젯
class AnimatedLiquid extends StatelessWidget {
  final AnimationController animationController;
  final Color color;
  final double height;
  final double? width;

  const AnimatedLiquid({
    Key? key,
    required this.animationController,
    required this.color,
    required this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // 0.3부터 0.7까지의 범위로 제한하여 물결이 항상 보이게 함
        final animValue = 0.3 + 0.4 * animationController.value;

        return ClipPath(
          clipper: LiquidClipper(
            fillLevel: animValue,
            wavesCount: 3,
            amplitude: 6 + 4 * animationController.value, // 진폭 변화 추가
          ),
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}

/// 물결 모양 클리퍼
class LiquidClipper extends CustomClipper<Path> {
  final double fillLevel; // 0.0부터 1.0까지의 채움 레벨
  final int wavesCount; // 물결 개수
  final double amplitude; // 물결 높이

  LiquidClipper({
    required this.fillLevel,
    this.wavesCount = 3,
    this.amplitude = 10,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // 최소 1%부터 최대 채움 레벨까지
    final fillHeight = size.height * (1.0 - math.max(0.01, fillLevel));
    final waveWidth = size.width / wavesCount;

    path.moveTo(0, fillHeight);

    // 물결 그리기
    for (int i = 0; i < wavesCount * 2; i++) {
      final x = waveWidth * i / 2;
      final y = fillHeight + (i.isEven ? amplitude : -amplitude);
      path.quadraticBezierTo(
        x + waveWidth / 4,
        fillHeight + (i.isEven ? -amplitude : amplitude),
        x + waveWidth / 2,
        y,
      );
    }

    // 컨테이너 나머지 부분 채우기
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(LiquidClipper oldClipper) {
    return oldClipper.fillLevel != fillLevel ||
        oldClipper.wavesCount != wavesCount ||
        oldClipper.amplitude != amplitude;
  }
}
