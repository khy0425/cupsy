import 'package:shared_preferences/shared_preferences.dart';

/// 일일 감정 컵 생성 제한을 관리하는 유틸리티 클래스
class DailyLimitManager {
  /// 저장소 키
  static const String _lastCreationDateKey = 'last_cup_creation_date';
  static const String _dailyCreationCountKey = 'daily_cup_creation_count';

  /// 하루 최대 생성 가능 횟수
  static const int maxDailyCreations = 1;

  /// 현재 일자에 대한 키 생성
  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// 오늘 생성한 컵 개수 가져오기
  static Future<int> getTodayCreationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    final lastCreationDate = prefs.getString(_lastCreationDateKey) ?? '';

    // 날짜가 다르면 카운트 초기화
    if (lastCreationDate != todayKey) {
      return 0;
    }

    return prefs.getInt(_dailyCreationCountKey) ?? 0;
  }

  /// 오늘 컵을 더 생성할 수 있는지 확인
  static Future<bool> canCreateCupToday() async {
    final todayCount = await getTodayCreationCount();
    return todayCount < maxDailyCreations;
  }

  /// 컵 생성 기록 저장
  static Future<void> recordCupCreation() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    final lastCreationDate = prefs.getString(_lastCreationDateKey) ?? '';

    if (lastCreationDate != todayKey) {
      // 날짜가 변경되었으면 카운트 초기화
      await prefs.setString(_lastCreationDateKey, todayKey);
      await prefs.setInt(_dailyCreationCountKey, 1);
    } else {
      // 같은 날짜면 카운트 증가
      final currentCount = prefs.getInt(_dailyCreationCountKey) ?? 0;
      await prefs.setInt(_dailyCreationCountKey, currentCount + 1);
    }
  }

  /// 다음 컵 생성까지 남은 시간 계산 (초 단위)
  static Future<int> getTimeToNextCreation() async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now).inSeconds;
  }

  /// 다음 컵 생성까지 남은 시간을 사람이 읽기 쉬운 형태로 변환
  static String formatTimeRemaining(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours시간 $minutes분 후 가능';
    } else if (minutes > 0) {
      return '$minutes분 후 가능';
    } else {
      return '1분 이내 가능';
    }
  }
}
