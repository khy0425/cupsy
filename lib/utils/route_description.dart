import 'package:flutter/material.dart';
import 'package:cupsy/utils/routes.dart';

/// 앱 내의 각 라우트에 대한 상세 설명을 담는 클래스입니다.
/// 경로, 제목, 아이콘 등의 메타데이터를 포함합니다.
class RouteDescription {
  final String path;
  final String title;
  final IconData icon;
  final bool showInMenu;
  final bool needsAuth;

  const RouteDescription({
    required this.path,
    required this.title,
    required this.icon,
    this.showInMenu = true,
    this.needsAuth = false,
  });
}

/// 앱 내의 모든 경로에 대한 메타데이터를 담고 있는 클래스입니다.
/// 이 정보는 메뉴 생성, 경로 처리, 접근 제어 등에 사용됩니다.
class AppRoutesDescription {
  static const Map<String, RouteDescription> routes = {
    AppRoutes.home: RouteDescription(
      path: AppRoutes.home,
      title: '홈',
      icon: Icons.home,
    ),
    AppRoutes.emotionSelection: RouteDescription(
      path: AppRoutes.emotionSelection,
      title: '감정 선택',
      icon: Icons.emoji_emotions,
    ),
    AppRoutes.situationSelection: RouteDescription(
      path: AppRoutes.situationSelection,
      title: '상황 선택',
      icon: Icons.place,
    ),
    AppRoutes.result: RouteDescription(
      path: AppRoutes.result,
      title: '감정 음료',
      icon: Icons.local_drink,
    ),
    AppRoutes.settings: RouteDescription(
      path: AppRoutes.settings,
      title: '설정',
      icon: Icons.settings,
    ),
    AppRoutes.history: RouteDescription(
      path: AppRoutes.history,
      title: '감정 기록',
      icon: Icons.history,
      needsAuth: true,
    ),
    AppRoutes.profile: RouteDescription(
      path: AppRoutes.profile,
      title: '프로필',
      icon: Icons.person,
      needsAuth: true,
    ),
    AppRoutes.about: RouteDescription(
      path: AppRoutes.about,
      title: '앱 정보',
      icon: Icons.info,
      showInMenu: false,
    ),
    AppRoutes.login: RouteDescription(
      path: AppRoutes.login,
      title: '로그인',
      icon: Icons.login,
      showInMenu: false,
    ),
    AppRoutes.register: RouteDescription(
      path: AppRoutes.register,
      title: '회원가입',
      icon: Icons.app_registration,
      showInMenu: false,
    ),
  };

  /// 메뉴에 표시할 경로들만 필터링해서 반환합니다.
  static List<RouteDescription> get menuRoutes {
    return routes.values.where((route) => route.showInMenu).toList();
  }

  /// 인증이 필요한 경로들만 필터링해서 반환합니다.
  static List<String> get authRequiredPaths {
    return routes.entries
        .where((entry) => entry.value.needsAuth)
        .map((entry) => entry.key)
        .toList();
  }
}
