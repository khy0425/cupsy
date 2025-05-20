import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';
import 'package:cupsy/models/emotion_cocktail_model.dart';
import 'package:cupsy/services/firebase_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// 스토리지 키
const String _unlockedCupsKey = 'unlocked_cups';
const String _unlockedCocktailsKey = 'unlocked_cocktails';

/// 데이터 저장소 추상 클래스 - 감정
abstract class EmotionRepository {
  Future<List<Emotion>> getAllEmotions();
  Future<Emotion?> getEmotionById(String id);
}

/// 데이터 저장소 추상 클래스 - 컵 디자인
abstract class CupDesignRepository {
  Future<List<CupDesign>> getAllCupDesigns();
  Future<List<CupDesign>> getCupDesignsByEmotion(String emotionId);
  Future<CupDesign?> getCupDesignById(String id);
  Future<void> unlockCupDesign(String id);
}

/// 데이터 저장소 추상 클래스 - 감정 꽃
abstract class EmotionFlowerRepository {
  Future<List<EmotionFlower>> getAllFlowers();
  Future<EmotionFlower?> getFlowerByName(String name);
  Future<List<EmotionFlower>> getFlowersByEmotionName(String emotionName);
}

/// 데이터 저장소 추상 클래스 - 감정 칵테일
abstract class EmotionCocktailRepository {
  Future<List<EmotionCocktail>> getAllCocktails();
  Future<EmotionCocktail?> getCocktailById(String id);
  Future<List<EmotionCocktail>> getUnlockedCocktails();
  Future<void> unlockCocktail(String id);
  Future<void> saveCocktail(EmotionCocktail cocktail);
}

/// 메모리 기반 감정 저장소
class MemoryEmotionRepository implements EmotionRepository {
  final List<Emotion> _emotions = EmotionData.emotions;

  @override
  Future<List<Emotion>> getAllEmotions() async {
    return _emotions;
  }

  @override
  Future<Emotion?> getEmotionById(String id) async {
    try {
      return _emotions.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// 메모리 기반 컵 디자인 저장소
class MemoryCupDesignRepository implements CupDesignRepository {
  final List<CupDesign> _cupDesigns = CupDesignsData.allDesigns;

  @override
  Future<List<CupDesign>> getAllCupDesigns() async {
    return _cupDesigns;
  }

  @override
  Future<List<CupDesign>> getCupDesignsByEmotion(String emotionId) async {
    return _cupDesigns
        .where((cup) => cup.emotionTags.contains(emotionId))
        .toList();
  }

  @override
  Future<CupDesign?> getCupDesignById(String id) async {
    try {
      return _cupDesigns.firstWhere((cup) => cup.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> unlockCupDesign(String id) async {
    final cupIndex = _cupDesigns.indexWhere((cup) => cup.id == id);
    if (cupIndex != -1) {
      _cupDesigns[cupIndex].isUnlocked = true;
      await _saveUnlockedCups();
    }
  }

  // 잠금 해제된 컵 목록 저장
  Future<void> _saveUnlockedCups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedIds =
          _cupDesigns
              .where((cup) => cup.isUnlocked)
              .map((cup) => cup.id)
              .toList();
      await prefs.setStringList(_unlockedCupsKey, unlockedIds);
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '잠금 해제된 컵 저장 실패',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // 잠금 해제된 컵 목록 로드
  Future<List<CupDesign>> loadUnlockedCups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> unlockedCups =
          prefs.getStringList(_unlockedCupsKey) ?? [];

      for (var cup in _cupDesigns) {
        if (unlockedCups.contains(cup.id)) {
          cup.isUnlocked = true;
        }
      }

      return _cupDesigns.where((cup) => cup.isUnlocked).toList();
    } catch (e) {
      ErrorHandlingService.logWarning('잠금 해제된 컵 디자인 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 로컬 데이터 초기화 (테스트 용도)
  Future<void> resetUnlockedCups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_unlockedCupsKey);

      // 모든 컵 디자인 잠금 설정 (기본 컵 제외)
      for (var cup in _cupDesigns) {
        if (cup.id != 'default') {
          cup.isUnlocked = false;
          cup.obtainedAt = null;
        }
      }
    } catch (e) {
      ErrorHandlingService.logWarning('컵 디자인 잠금 상태 초기화 실패: $e');
    }
  }
}

/// 로컬 데이터 저장소 구현 - 감정별 꽃
class LocalEmotionFlowerRepository implements EmotionFlowerRepository {
  @override
  Future<List<EmotionFlower>> getAllFlowers() async {
    return EmotionFlowerData.flowers;
  }

  @override
  Future<EmotionFlower?> getFlowerByName(String name) async {
    try {
      return EmotionFlowerData.flowers.firstWhere(
        (flower) => flower.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<EmotionFlower>> getFlowersByEmotionName(
    String emotionName,
  ) async {
    return EmotionFlowerData.flowers
        .where((flower) => flower.emotion.name == emotionName)
        .toList();
  }
}

/// 데이터 저장소 팩토리
class RepositoryFactory {
  static final RepositoryFactory _instance = RepositoryFactory._internal();
  factory RepositoryFactory() => _instance;
  RepositoryFactory._internal();

  // Firebase 연결 상태에 따라 적절한 저장소 반환
  Future<bool> get isFirebaseAvailable async {
    final firebaseService = FirebaseService();
    return await firebaseService.checkStatus();
  }

  // 감정 저장소
  Future<EmotionRepository> getEmotionRepository() async {
    return MemoryEmotionRepository();
  }

  // 컵 디자인 저장소
  Future<CupDesignRepository> getCupDesignRepository() async {
    return MemoryCupDesignRepository();
  }

  // 감정별 꽃 저장소
  Future<EmotionFlowerRepository> getEmotionFlowerRepository() async {
    return LocalEmotionFlowerRepository();
  }

  // 감정 칵테일 저장소
  Future<EmotionCocktailRepository> getEmotionCocktailRepository() async {
    // 일단 로컬 구현으로 대체
    throw UnimplementedError("아직 구현되지 않았습니다");
  }
}
