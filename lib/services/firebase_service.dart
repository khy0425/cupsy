import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Firebase 관련 서비스를 관리하는 클래스
class FirebaseService {
  // 싱글톤 인스턴스
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // 로깅
  final Logger _logger = Logger();

  // 서비스 초기화 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Firebase Analytics 인스턴스
  FirebaseAnalytics? _analytics;
  FirebaseAnalytics? get analytics => _analytics;

  /// Firebase 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.i('Firebase 서비스가 이미 초기화되었습니다.');
      return;
    }

    try {
      _logger.i('Firebase 초기화 시작...');

      // Firebase 초기화
      await Firebase.initializeApp();

      // Firebase Analytics 설정
      _analytics = FirebaseAnalytics.instance;

      _isInitialized = true;
      _logger.i('Firebase 초기화 완료');
    } catch (e, stackTrace) {
      _logger.e('Firebase 초기화 실패: $e');
      ErrorHandlingService.logError(
        'Firebase 초기화 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );

      // Firebase 없이도 앱이 작동할 수 있도록 함
      _isInitialized = false;
    }
  }

  /// Firebase 서비스 상태 확인
  Future<bool> checkStatus() async {
    if (!_isInitialized) {
      _logger.w('Firebase 서비스가 초기화되지 않았습니다.');
      return false;
    }

    try {
      // 간단한 테스트로 Firebase 연결 확인
      await _analytics?.logEvent(name: 'app_status_check');
      return true;
    } catch (e) {
      _logger.e('Firebase 상태 확인 실패: $e');
      return false;
    }
  }

  /// 앱 재시작 시 Firebase 재연결
  Future<void> reconnect() async {
    if (_isInitialized) {
      try {
        await Firebase.app().delete();
        _isInitialized = false;
      } catch (e) {
        _logger.e('Firebase 앱 삭제 실패: $e');
      }
    }

    await initialize();
  }

  /// Firebase 서비스 종료
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await Firebase.app().delete();
      _isInitialized = false;
      _logger.i('Firebase 서비스가 종료되었습니다.');
    } catch (e, stackTrace) {
      _logger.e('Firebase 종료 실패: $e');
      ErrorHandlingService.logError(
        'Firebase 종료 중 오류 발생',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
