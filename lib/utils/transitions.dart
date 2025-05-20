import 'package:flutter/material.dart';

/// 앱에서 사용되는 화면 전환 애니메이션을 관리하는 클래스입니다.
/// 다양한 사용자 지정 페이지 전환 효과를 제공합니다.
class AppTransitions {
  /// 페이드 인/아웃 전환 효과를 생성합니다.
  static PageRouteBuilder<T> fadeTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// 슬라이드 전환 효과를 생성합니다. 방향을 지정할 수 있습니다.
  static PageRouteBuilder<T> slideTransition<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.fromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Offset begin;

    switch (direction) {
      case SlideDirection.fromRight:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.fromLeft:
        begin = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.fromTop:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.fromBottom:
        begin = const Offset(0.0, 1.0);
        break;
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// 확대/축소 전환 효과를 생성합니다.
  static PageRouteBuilder<T> scaleTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.5,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// 결합된 전환 효과: 페이드와 슬라이드
  static PageRouteBuilder<T> fadeSlideTransition<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.fromRight,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    Offset begin;

    switch (direction) {
      case SlideDirection.fromRight:
        begin = const Offset(0.2, 0.0);
        break;
      case SlideDirection.fromLeft:
        begin = const Offset(-0.2, 0.0);
        break;
      case SlideDirection.fromTop:
        begin = const Offset(0.0, -0.2);
        break;
      case SlideDirection.fromBottom:
        begin = const Offset(0.0, 0.2);
        break;
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween(
              begin: begin,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

/// 슬라이드 방향 열거형
enum SlideDirection { fromRight, fromLeft, fromTop, fromBottom }
