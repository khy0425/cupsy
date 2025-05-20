import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 데이터 저장 및 관리를 위한 서비스 클래스
class PreferencesService {
  static SharedPreferences? _preferences;

  // 키 상수들
  static const String lastCreatedDateKey = 'last_created_date';
  static const String usageCountKey = 'usage_count';

  /// 서비스 초기화
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// 마지막 컵 생성 날짜 저장
  static Future<bool> setLastCreatedDate(DateTime date) async {
    return await _preferences?.setString(
          lastCreatedDateKey,
          date.toIso8601String(),
        ) ??
        false;
  }

  /// 마지막 컵 생성 날짜 가져오기
  static DateTime? getLastCreatedDate() {
    final dateString = _preferences?.getString(lastCreatedDateKey);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('날짜 파싱 오류: $e');
      return null;
    }
  }

  /// 오늘 이미 컵을 생성했는지 확인
  static bool hasCreatedToday() {
    final lastCreated = getLastCreatedDate();
    if (lastCreated == null) return false;

    final now = DateTime.now();
    return lastCreated.year == now.year &&
        lastCreated.month == now.month &&
        lastCreated.day == now.day;
  }

  /// 앱 사용 횟수 증가
  static Future<bool> incrementUsageCount() async {
    final currentCount = _preferences?.getInt(usageCountKey) ?? 0;
    return await _preferences?.setInt(usageCountKey, currentCount + 1) ?? false;
  }

  /// 앱 사용 횟수 가져오기
  static int getUsageCount() {
    return _preferences?.getInt(usageCountKey) ?? 0;
  }

  /// 모든 저장 데이터 삭제 (초기화)
  static Future<bool> clearAllData() async {
    return await _preferences?.clear() ?? false;
  }
}
