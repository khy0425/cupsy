import 'package:flutter/material.dart';
import 'package:cupsy/utils/routes.dart';

/// 앱 내에서 화면 간 네비게이션을 쉽게 해주는 서비스 클래스입니다.
/// 명시적인 context 전달 없이도 네비게이션이 가능하도록 글로벌 키를 사용합니다.
class NavigationService {
  // 글로벌 키를 사용하여 네비게이터 상태에 접근
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // 네비게이터 상태 가져오기 (null 가능)
  static NavigatorState? get navigator => navigatorKey.currentState;

  // 새 화면으로 이동
  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  // 현재 화면을 대체하여 이동
  static Future<T?> replaceTo<T>(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  // 이전 화면으로 돌아가기
  static void goBack<T>({T? result}) {
    return navigator!.pop(result);
  }

  // 홈 화면으로 이동하며 스택 비우기
  static void navigateToHome() {
    navigator!.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  // 특정 화면까지 스택 비우기
  static void navigateUntil(
    String routeName, {
    Object? arguments,
    required RoutePredicate predicate,
  }) {
    navigator!.pushNamedAndRemoveUntil(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  // 감정 선택 화면으로 이동
  static Future<T?> navigateToEmotionSelection<T>() {
    return navigateTo<T>(AppRoutes.emotionSelection);
  }

  // 상황 선택 화면으로 이동
  static Future<T?> navigateToSituationSelection<T>({
    required String emotionId,
  }) {
    return navigateTo<T>(
      AppRoutes.situationSelection,
      arguments: {'emotionId': emotionId},
    );
  }

  // 결과 화면으로 이동
  static Future<T?> navigateToResult<T>({
    required String emotionId,
    required String situationId,
  }) {
    return navigateTo<T>(
      AppRoutes.result,
      arguments: {'emotionId': emotionId, 'situationId': situationId},
    );
  }

  // 설정 화면으로 이동
  static Future<T?> navigateToSettings<T>() {
    return navigateTo<T>(AppRoutes.settings);
  }

  // 프로필 화면으로 이동
  static Future<T?> navigateToProfile<T>() {
    return navigateTo<T>(AppRoutes.profile);
  }

  // 이력 화면으로 이동
  static Future<T?> navigateToHistory<T>() {
    return navigateTo<T>(AppRoutes.history);
  }
}
