import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/situation.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/models/emotion_flower_model.dart';

/// 생성된 감정 컵 정보를 담는 클래스
class EmotionCupModel {
  final String id;
  final Emotion emotion;
  final Situation situation;
  final DateTime createdAt;
  final String title;
  final String description;
  final CupDesign? cupDesign;
  final EmotionFlower? flower;

  EmotionCupModel({
    required this.id,
    required this.emotion,
    required this.situation,
    required this.createdAt,
    required this.title,
    required this.description,
    this.cupDesign,
    this.flower,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emotionId': emotion.id,
      'situationId': situation.id,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'description': description,
      'cupDesignId': cupDesign?.id,
      'flowerId': flower?.name,
    };
  }

  // JSON에서 변환 (모든 객체 참조 필요)
  static EmotionCupModel fromJson(
    Map<String, dynamic> json,
    List<Emotion> allEmotions,
    List<Situation> allSituations,
    List<CupDesign> allCupDesigns,
    List<EmotionFlower> allFlowers,
  ) {
    // 감정 찾기
    final emotion = allEmotions.firstWhere(
      (e) => e.id == json['emotionId'],
      orElse: () => EmotionData.emotions.first,
    );

    // 상황 찾기
    final situation = allSituations.firstWhere(
      (s) => s.id == json['situationId'],
      orElse: () => SituationData.situations.first,
    );

    // 컵 디자인 찾기 (선택적)
    CupDesign? cupDesign;
    if (json['cupDesignId'] != null) {
      try {
        cupDesign = allCupDesigns.firstWhere(
          (c) => c.id == json['cupDesignId'],
        );
      } catch (_) {
        // 찾지 못한 경우 null 유지
      }
    }

    // 꽃 찾기 (선택적)
    EmotionFlower? flower;
    if (json['flowerId'] != null) {
      try {
        flower = allFlowers.firstWhere((f) => f.name == json['flowerId']);
      } catch (_) {
        // 찾지 못한 경우 null 유지
      }
    }

    return EmotionCupModel(
      id: json['id'],
      emotion: emotion,
      situation: situation,
      createdAt: DateTime.parse(json['createdAt']),
      title: json['title'],
      description: json['description'],
      cupDesign: cupDesign,
      flower: flower,
    );
  }
}
