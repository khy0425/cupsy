import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cupsy/screens/home_screen.dart';
import 'package:cupsy/screens/emotion_selection_screen.dart';
import 'package:cupsy/screens/situation_selection_screen.dart';
import 'package:cupsy/screens/result_screen.dart';
import 'package:cupsy/screens/settings_screen.dart';
import 'package:cupsy/screens/collection_screen.dart';
import 'package:cupsy/screens/stats_screen.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:cupsy/utils/transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GoRouter 인스턴스를 제공하는 provider.
/// 이를 통해 앱 전체에서 라우터에 접근할 수 있습니다.
final routerProvider = Provider<GoRouter>((ref) => AppRouter.router);

/// 앱의 라우팅 구성을 정의하는 클래스입니다.
/// GoRouter를 사용하여 선언적 라우팅을 구현합니다.
class AppRouter {
  /// 글로벌 키를 사용하여 네비게이터 상태에 접근
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// 앱 전체에서 사용할 GoRouter 인스턴스
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true, // 개발용 로깅 활성화
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.emotionSelection,
        name: 'emotionSelection',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EmotionSelectionScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.situationSelection,
        name: 'situationSelection',
        pageBuilder: (context, state) {
          // URL 쿼리 파라미터에서 emotionId 추출
          final emotionId = state.queryParameters['emotionId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: SituationSelectionScreen(emotionId: emotionId),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              // 페이드와 슬라이드를 조합한 전환 애니메이션
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              return FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0.0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.result,
        name: 'result',
        pageBuilder: (context, state) {
          // URL 쿼리 파라미터에서 emotionId와 situationId 추출
          final emotionId = state.queryParameters['emotionId'] ?? '';
          final situationId = state.queryParameters['situationId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ResultScreen(emotionId: emotionId, situationId: situationId),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              // 확대 애니메이션
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              return ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(curvedAnimation),
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
        },
      ),
      // 설정 화면 라우터 설정 업데이트
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('감정 기록 화면 - 구현 예정')),
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(body: Center(child: Text('프로필 화면 - 구현 예정'))),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(body: Center(child: Text('앱 정보 화면 - 구현 예정'))),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      // 컬렉션 화면 라우트
      GoRoute(
        path: AppRoutes.collection,
        name: 'collection',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CollectionScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      // 통계 화면 라우트 추가
      GoRoute(
        path: AppRoutes.stats,
        name: 'stats',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const StatsScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
    ],
    // 에러 처리: 페이지를 찾을 수 없는 경우
    errorPageBuilder: (context, state) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '요청한 페이지를 찾을 수 없습니다.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('홈으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
    // 리다이렉션: 인증이 필요한 경로 접근 시 처리 (향후 구현)
    redirect: (context, state) {
      // 여기에서 인증 상태를 확인하고 필요한 경우 리다이렉션 수행
      return null; // null 반환 시 리다이렉션 없음
    },
  );
}
