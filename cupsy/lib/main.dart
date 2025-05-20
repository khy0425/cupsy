import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupsy/utils/preferences_service.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/screens/home_screen.dart';
import 'package:cupsy/screens/emotion_selection_screen.dart';
import 'package:cupsy/screens/situation_selection_screen.dart';
import 'package:cupsy/screens/result_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences 초기화
  await PreferencesService.init();

  // 모바일 광고 초기화
  await MobileAds.instance.initialize();

  runApp(
    // ProviderScope로 감싸서 Riverpod 사용 가능하게 함
    const ProviderScope(child: Cupsy()),
  );
}

class Cupsy extends StatelessWidget {
  const Cupsy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupsy',
      theme: AppTheme.lightTheme, // 커스텀 테마 적용
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/emotion': (context) => const EmotionSelectionScreen(),
        '/situation': (context) => const SituationSelectionScreen(),
        '/result': (context) => const ResultScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
