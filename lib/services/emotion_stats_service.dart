import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/emotion_cup_model.dart';
import 'package:cupsy/models/situation.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 감정 기록을 저장할 키
const String _emotionRecordsKey = 'emotional_records';

/// 감정 통계 항목 클래스
class EmotionStat {
  final Emotion emotion;
  final int count;
  final double percentage;

  EmotionStat({
    required this.emotion,
    required this.count,
    required this.percentage,
  });
}

/// 상황 통계 항목 클래스
class SituationStat {
  final Situation situation;
  final int count;
  final double percentage;

  SituationStat({
    required this.situation,
    required this.count,
    required this.percentage,
  });
}

/// 시간대별 통계 항목 클래스
class TimeOfDayStat {
  final String timeSlot;
  final int count;

  TimeOfDayStat({required this.timeSlot, required this.count});
}

/// 요일별 통계 항목 클래스
class DayOfWeekStat {
  final String dayName;
  final int count;

  DayOfWeekStat({required this.dayName, required this.count});
}

/// 감정 통계 서비스 클래스
class EmotionStatsService {
  static final EmotionStatsService _instance = EmotionStatsService._internal();
  factory EmotionStatsService() => _instance;
  EmotionStatsService._internal();

  bool _initialized = false;
  List<EmotionCupModel> _allRecords = [];

  // 감정 및 상황 목록 참조
  final List<Emotion> _allEmotions = EmotionData.emotions;
  final List<Situation> _allSituations = SituationData.situations;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_emotionRecordsKey);

      if (recordsJson != null && recordsJson.isNotEmpty) {
        _allRecords =
            recordsJson
                .map(
                  (jsonString) =>
                      json.decode(jsonString) as Map<String, dynamic>,
                )
                .map(
                  (json) => EmotionCupModel.fromJson(
                    json,
                    _allEmotions,
                    _allSituations,
                    [], // 컵 디자인 (현재는 비어 있음)
                    [], // 꽃 (현재는 비어 있음)
                  ),
                )
                .toList();
      } else {
        // 데모 데이터 추가 (실제 구현에서는 제거)
        _allRecords = _generateDemoData();
      }

      _initialized = true;
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '감정 통계 서비스 초기화 실패',
        error: e,
        stackTrace: stackTrace,
      );
      // 초기화 실패 시 데모 데이터 사용
      _allRecords = _generateDemoData();
      _initialized = true;
    }
  }

  /// 모든 감정 기록 가져오기
  Future<List<EmotionCupModel>> getAllRecords() async {
    if (!_initialized) await initialize();
    return List.from(_allRecords);
  }

  /// 감정별 통계 가져오기
  Future<List<EmotionStat>> getEmotionStats() async {
    if (!_initialized) await initialize();

    if (_allRecords.isEmpty) {
      return [];
    }

    // 각 감정별 카운트
    final Map<String, int> emotionCounts = {};

    for (final record in _allRecords) {
      final emotionId = record.emotion.id;
      emotionCounts[emotionId] = (emotionCounts[emotionId] ?? 0) + 1;
    }

    // 통계 계산
    final totalCount = _allRecords.length;
    final stats = <EmotionStat>[];

    for (final entry in emotionCounts.entries) {
      final emotion = _allEmotions.firstWhere(
        (e) => e.id == entry.key,
        orElse: () => _allEmotions.first,
      );

      final count = entry.value;
      final percentage = (count / totalCount) * 100;

      stats.add(
        EmotionStat(emotion: emotion, count: count, percentage: percentage),
      );
    }

    // 카운트 기준 내림차순 정렬
    stats.sort((a, b) => b.count.compareTo(a.count));

    return stats;
  }

  /// 상황별 통계 가져오기
  Future<List<SituationStat>> getSituationStats() async {
    if (!_initialized) await initialize();

    if (_allRecords.isEmpty) {
      return [];
    }

    // 각 상황별 카운트
    final Map<String, int> situationCounts = {};

    for (final record in _allRecords) {
      final situationId = record.situation.id;
      situationCounts[situationId] = (situationCounts[situationId] ?? 0) + 1;
    }

    // 통계 계산
    final totalCount = _allRecords.length;
    final stats = <SituationStat>[];

    for (final entry in situationCounts.entries) {
      final situation = _allSituations.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => _allSituations.first,
      );

      final count = entry.value;
      final percentage = (count / totalCount) * 100;

      stats.add(
        SituationStat(
          situation: situation,
          count: count,
          percentage: percentage,
        ),
      );
    }

    // 카운트 기준 내림차순 정렬
    stats.sort((a, b) => b.count.compareTo(a.count));

    return stats;
  }

  /// 시간대별 통계 가져오기
  Future<List<TimeOfDayStat>> getTimeOfDayStats() async {
    if (!_initialized) await initialize();

    if (_allRecords.isEmpty) {
      return [];
    }

    // 시간대 정의
    final timeSlots = {
      '아침 (6시-9시)': const TimeOfDay(hour: 6, minute: 0),
      '오전 (9시-12시)': const TimeOfDay(hour: 9, minute: 0),
      '오후 (12시-18시)': const TimeOfDay(hour: 12, minute: 0),
      '저녁 (18시-21시)': const TimeOfDay(hour: 18, minute: 0),
      '밤 (21시-24시)': const TimeOfDay(hour: 21, minute: 0),
      '새벽 (0시-6시)': const TimeOfDay(hour: 0, minute: 0),
    };

    // 각 시간대별 카운트
    final Map<String, int> timeCounts = {};

    for (final slot in timeSlots.keys) {
      timeCounts[slot] = 0;
    }

    for (final record in _allRecords) {
      final hour = record.createdAt.hour;

      String timeSlot;
      if (hour >= 6 && hour < 9) {
        timeSlot = '아침 (6시-9시)';
      } else if (hour >= 9 && hour < 12) {
        timeSlot = '오전 (9시-12시)';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = '오후 (12시-18시)';
      } else if (hour >= 18 && hour < 21) {
        timeSlot = '저녁 (18시-21시)';
      } else if (hour >= 21 && hour < 24) {
        timeSlot = '밤 (21시-24시)';
      } else {
        timeSlot = '새벽 (0시-6시)';
      }

      timeCounts[timeSlot] = (timeCounts[timeSlot] ?? 0) + 1;
    }

    // 통계 구성
    final stats = <TimeOfDayStat>[];

    for (final entry in timeCounts.entries) {
      stats.add(TimeOfDayStat(timeSlot: entry.key, count: entry.value));
    }

    return stats;
  }

  /// 요일별 통계 가져오기
  Future<List<DayOfWeekStat>> getDayOfWeekStats() async {
    if (!_initialized) await initialize();

    if (_allRecords.isEmpty) {
      return [];
    }

    // 요일 정의
    final dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

    // 각 요일별 카운트
    final Map<String, int> dayCounts = {};

    for (final day in dayNames) {
      dayCounts[day] = 0;
    }

    for (final record in _allRecords) {
      final weekday = record.createdAt.weekday; // 1(월) ~ 7(일)
      final dayName = dayNames[weekday - 1];
      dayCounts[dayName] = (dayCounts[dayName] ?? 0) + 1;
    }

    // 통계 구성
    final stats = <DayOfWeekStat>[];

    for (final entry in dayCounts.entries) {
      stats.add(DayOfWeekStat(dayName: entry.key, count: entry.value));
    }

    return stats;
  }

  /// 월별 기록 수 가져오기 (최근 6개월)
  Future<Map<String, int>> getMonthlyRecordCounts() async {
    if (!_initialized) await initialize();

    if (_allRecords.isEmpty) {
      return {};
    }

    // 월별 카운트
    final Map<String, int> monthlyCounts = {};

    // 최근 6개월 기간 설정
    final now = DateTime.now();

    for (var i = 0; i < 6; i++) {
      final month = now.month - i;
      final year = now.year - (month <= 0 ? 1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final key = '$year.${adjustedMonth.toString().padLeft(2, '0')}';
      monthlyCounts[key] = 0;
    }

    // 기록 카운트
    for (final record in _allRecords) {
      final date = record.createdAt;
      final key = '${date.year}.${date.month.toString().padLeft(2, '0')}';

      if (monthlyCounts.containsKey(key)) {
        monthlyCounts[key] = (monthlyCounts[key] ?? 0) + 1;
      }
    }

    return monthlyCounts;
  }

  /// 가장 많이 기록된 감정 가져오기
  Future<EmotionStat?> getMostFrequentEmotion() async {
    final stats = await getEmotionStats();
    return stats.isNotEmpty ? stats.first : null;
  }

  /// 데모 데이터 생성 (개발 및 테스트용)
  List<EmotionCupModel> _generateDemoData() {
    // 현재 날짜를 기준으로 과거 데이터 생성
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch;
    final demoRecords = <EmotionCupModel>[];

    // 최근 50일간의 데이터 생성
    for (var i = 0; i < 50; i++) {
      // 생성할 기록 수 (0~3)
      final recordsPerDay = (random % (i + 3)) % 3;

      for (var j = 0; j < recordsPerDay; j++) {
        final randomEmotionIndex = (random + i * j) % _allEmotions.length;
        final randomSituationIndex =
            (random + i * j + 1) % _allSituations.length;

        // 날짜 생성 (과거 i일 전, 랜덤 시간)
        final date = DateTime(
          now.year,
          now.month,
          now.day - i,
          (random + i * j) % 24, // 시간
          (random + i * j + 2) % 60, // 분
        );

        demoRecords.add(
          EmotionCupModel(
            id: 'demo_${i}_$j',
            emotion: _allEmotions[randomEmotionIndex],
            situation: _allSituations[randomSituationIndex],
            createdAt: date,
            title: '데모 감정 ${i + j}',
            description: '데모 데이터로 생성된 감정 기록입니다.',
          ),
        );
      }
    }

    return demoRecords;
  }
}
