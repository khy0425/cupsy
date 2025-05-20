import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

/// 애플리케이션의 오류 처리를 담당하는 서비스
class ErrorHandlingService {
  // 싱글톤 인스턴스
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // 로거 인스턴스
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // 초기화 상태
  static bool _isInitialized = false;

  /// 오류 처리 서비스 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 글로벌 오류 핸들러 설정
      setupErrorHandlers();
      _isInitialized = true;
      _instance._logInfo('오류 처리 서비스가 초기화되었습니다.');
    } catch (e, stackTrace) {
      print('오류 처리 서비스 초기화 중 오류 발생: $e');
      print(stackTrace);
    }
  }

  /// 사용자 친화적인 오류 메시지 반환
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return '네트워크 연결에 문제가 있습니다. 인터넷 연결을 확인해주세요.';
    } else if (error is AuthException) {
      return '인증에 문제가 발생했습니다. 다시 로그인해주세요.';
    } else if (error is DataException) {
      return '데이터 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else if (error is PermissionException) {
      return '앱 권한이 부족합니다. 설정에서 필요한 권한을 허용해주세요.';
    } else if (error is Exception) {
      return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else {
      return '알 수 없는 오류가 발생했습니다. 앱을 재시작해주세요.';
    }
  }

  // 정적 메서드
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _instance._logError(message, error: error, stackTrace: stackTrace);
  }

  static void logWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _instance._logWarning(message, error: error, stackTrace: stackTrace);
  }

  static void logInfo(String message) {
    _instance._logInfo(message);
  }

  /// 오류 처리 래퍼 함수
  static Future<void> handleErrors(
    Future<void> Function() operation, {
    String operationName = '작업',
  }) async {
    try {
      await operation();
    } catch (e, stackTrace) {
      logError('$operationName 실행 중 오류 발생', error: e, stackTrace: stackTrace);
    }
  }

  // 오류 로깅
  void _logError(String message, {Object? error, StackTrace? stackTrace}) {
    // 디버그 모드에서 콘솔에 출력
    _logger.e('$message ${error != null ? '\nError: $error' : ''}');

    // 릴리스 모드에서는 Sentry에 보고
    if (!kDebugMode && error != null) {
      _reportToSentry(message, error, stackTrace);
    }
  }

  // 경고 로깅
  void _logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w('$message ${error != null ? '\nError: $error' : ''}');

    // 중요한 경고만 Sentry에 보고 (선택적)
    if (!kDebugMode && error != null && _isCriticalWarning(error)) {
      _reportToSentry(message, error, stackTrace, SentryLevel.warning);
    }
  }

  // 정보 로깅
  void _logInfo(String message) {
    _logger.i(message);
  }

  // Sentry 보고
  Future<void> _reportToSentry(
    String message,
    Object error,
    StackTrace? stackTrace, [
    SentryLevel level = SentryLevel.error,
  ]) async {
    try {
      // Sentry 8.x 버전의 올바른 사용법
      final sentryId = await Sentry.captureException(
        error,
        stackTrace: stackTrace ?? StackTrace.current,
      );

      _logger.i('Sentry에 오류가 보고되었습니다: $sentryId');
    } catch (e) {
      // Sentry 보고 자체에 문제가 있는 경우 로컬 로그만 남김
      _logger.e('Sentry 보고 중 오류 발생: $e');
    }
  }

  // 심각한 경고 여부 확인
  bool _isCriticalWarning(Object error) {
    // 여기서 심각한 경고를 구분하는 로직 구현
    // 예: 특정 클래스의 오류, 특정 패턴의 메시지 등
    return error.toString().contains('critical') ||
        error.toString().contains('security') ||
        error is StateError;
  }

  // 글로벌 예외 핸들러 설정
  static void setupErrorHandlers() {
    // Flutter 특화 오류 처리
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // 디버그 모드에서는 기본 처리
        FlutterError.dumpErrorToConsole(details);
      } else {
        // 릴리스 모드에서는 Sentry로 보고
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      }
    };

    // 비동기 및 영역 오류 처리
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._logError(
        'Uncaught platform error',
        error: error,
        stackTrace: stack,
      );
      return true; // 오류 처리됨
    };
  }
}

/// 앱 전용 예외 클래스
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => code != null ? '$code: $message' : message;
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalError})
    : super(
        message,
        code: code ?? 'NETWORK_ERROR',
        originalError: originalError,
      );
}

/// 인증 관련 예외
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic originalError})
    : super(message, code: code ?? 'AUTH_ERROR', originalError: originalError);
}

/// 데이터 처리 관련 예외
class DataException extends AppException {
  DataException(String message, {String? code, dynamic originalError})
    : super(message, code: code ?? 'DATA_ERROR', originalError: originalError);
}

/// 권한 관련 예외
class PermissionException extends AppException {
  PermissionException(String message, {String? code, dynamic originalError})
    : super(
        message,
        code: code ?? 'PERMISSION_ERROR',
        originalError: originalError,
      );
}
