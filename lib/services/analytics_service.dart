import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 앱 사용자 통계 및 이벤트 추적을 위한 분석 서비스
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  late FirebaseAnalytics _analytics;
  bool _initialized = false;
  bool _optOut = false;

  /// 내부 생성자
  AnalyticsService._internal();

  /// 분석 서비스 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;

      // 분석 옵션 상태 로드
      final prefs = await SharedPreferences.getInstance();
      _optOut = prefs.getBool('analytics_opt_out') ?? false;

      _initialized = true;

      if (kDebugMode) {
        await _analytics.setAnalyticsCollectionEnabled(false);
      } else {
        await _analytics.setAnalyticsCollectionEnabled(true);
      }

      ErrorHandlingService.logInfo('분석 서비스가 초기화되었습니다. 옵트아웃 상태: $_optOut');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '분석 서비스 초기화 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 분석 옵션 설정
  Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      _optOut = !enabled;

      // 사용자 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_opt_out', _optOut);

      // Firebase 분석 콜렉션 설정
      await _analytics.setAnalyticsCollectionEnabled(enabled);

      ErrorHandlingService.logInfo('분석 설정이 업데이트되었습니다. 활성화: $enabled');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '분석 설정 업데이트 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 분석 정보가 활성화되어 있는지 확인
  bool get isEnabled => !_optOut;

  /// 사용자 ID 설정
  Future<void> setUserId(String? userId) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.setUserId(id: userId);
      ErrorHandlingService.logInfo('사용자 ID가 설정되었습니다: $userId');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '사용자 ID 설정 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.setUserProperty(name: name, value: value);
      ErrorHandlingService.logInfo('사용자 속성이 설정되었습니다: $name=$value');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '사용자 속성 설정 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 화면 방문 로깅
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? 'Flutter',
      );
      ErrorHandlingService.logInfo('화면 방문 로깅: $screenName');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '화면 방문 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 감정 선택 이벤트 로깅
  Future<void> logEmotionSelected(String emotionId, String emotionName) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: 'emotion_selected',
        parameters: {'emotion_id': emotionId, 'emotion_name': emotionName},
      );
      ErrorHandlingService.logInfo('감정 선택 로깅: $emotionName ($emotionId)');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 선택 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 감정 칵테일 선택 이벤트 로깅
  Future<void> logEmotionCocktailSelected(
    String emotionIds,
    String emotionNames,
  ) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: 'emotion_cocktail_selected',
        parameters: {
          'emotion_ids': emotionIds,
          'emotion_names': emotionNames,
          'emotion_count': emotionIds.split(',').length,
        },
      );
      ErrorHandlingService.logInfo('감정 칵테일 선택 로깅: $emotionNames');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 칵테일 선택 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 상황 선택 이벤트 로깅
  Future<void> logSituationSelected(
    String situationId,
    String situationName,
    String emotionId,
  ) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: 'situation_selected',
        parameters: {
          'situation_id': situationId,
          'situation_name': situationName,
          'emotion_id': emotionId,
        },
      );
      ErrorHandlingService.logInfo(
        '상황 선택 로깅: $situationName ($situationId) for emotion $emotionId',
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '상황 선택 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 컵 생성 이벤트 로깅
  Future<void> logCupGenerated(String emotionId, String situationId) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: 'cup_generated',
        parameters: {
          'emotion_id': emotionId,
          'situation_id': situationId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      ErrorHandlingService.logInfo(
        '컵 생성 로깅: emotion=$emotionId, situation=$situationId',
      );
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '컵 생성 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 공유 이벤트 로깅
  Future<void> logShare(String contentType, String method) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: 'cup_image',
        method: method,
      );
      ErrorHandlingService.logInfo('공유 로깅: $contentType via $method');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '공유 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 일반 이벤트 로깅
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      ErrorHandlingService.logInfo('이벤트 로깅: $name, 파라미터: $parameters');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '이벤트 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 앱 오류 로깅
  Future<void> logAppError(String errorType, String errorDetails) async {
    if (_optOut || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_details': errorDetails,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      ErrorHandlingService.logInfo('앱 오류 로깅: $errorType');
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '앱 오류 로깅 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
