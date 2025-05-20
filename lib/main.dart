import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/utils/router_config.dart';
import 'package:cupsy/screens/settings_screen.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase 초기화
    await Firebase.initializeApp();

    // 에러 핸들링 서비스 초기화
    await ErrorHandlingService.initialize();

    // 분석 서비스 초기화
    await AnalyticsService.instance.initialize();

    // Sentry 초기화 및 앱 실행
    await SentryFlutter.init((options) {
      options.dsn = 'https://example@sentry.io/example';
      options.tracesSampleRate = 1.0;
    }, appRunner: () => runApp(const ProviderScope(child: CupsyApp())));
  } catch (e, stackTrace) {
    // 초기화 중 발생한 오류 로깅
    ErrorHandlingService.logError(
      '앱 초기화 중 오류가 발생했습니다',
      error: e,
      stackTrace: stackTrace,
    );

    // 오류가 발생해도 앱이 실행되도록 함
    runApp(const ProviderScope(child: CupsyApp()));
  }
}

/// Cupsy 앱의 루트 위젯
class CupsyApp extends ConsumerWidget {
  const CupsyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 모드 구독
    final themeMode = ref.watch(themeProvider);

    // 라우터 인스턴스 가져오기
    final routerConfig = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cupsy',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: routerConfig,
    );
  }
}
