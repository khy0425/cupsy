import 'package:cupsy/models/emotion_model.dart';
import 'package:flutter/material.dart';

/// 감정별 꽃과 꽃말 모델
class EmotionFlower {
  final Emotion emotion; // 연관된 감정
  final String name; // 꽃 이름
  final String flowerMeaning; // 꽃말
  final String imageUrl; // 꽃 이미지 경로

  EmotionFlower({
    required this.emotion,
    required this.name,
    required this.flowerMeaning,
    required this.imageUrl,
  });

  // JSON 변환 생성자
  factory EmotionFlower.fromJson(
    Map<String, dynamic> json,
    List<Emotion> emotions,
  ) {
    // emotion ID로 emotion 객체 찾기
    final emotion = emotions.firstWhere(
      (e) => e.id == json['emotionId'],
      orElse: () => EmotionData.emotions[0], // 기본값으로 첫번째 감정 사용
    );

    return EmotionFlower(
      emotion: emotion,
      name: json['name'],
      flowerMeaning: json['flowerMeaning'],
      imageUrl: json['imageUrl'],
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'emotionId': emotion.id,
      'name': name,
      'flowerMeaning': flowerMeaning,
      'imageUrl': imageUrl,
    };
  }
}

/// 사전 정의된 감정별 꽃 데이터
class EmotionFlowerData {
  static List<EmotionFlower> flowers = [
    // 기쁨 - 해바라기
    EmotionFlower(
      emotion: EmotionData.emotions[0], // 기쁨
      name: '해바라기',
      flowerMeaning: '당신만을 바라봅니다, 기쁨, 충성',
      imageUrl: 'assets/images/flowers/sunflower.png',
    ),

    // 평온 - 라벤더
    EmotionFlower(
      emotion: EmotionData.emotions[1], // 평온
      name: '라벤더',
      flowerMeaning: '평온, 고요, 기다림',
      imageUrl: 'assets/images/flowers/lavender.png',
    ),

    // 슬픔 - 파란 장미
    EmotionFlower(
      emotion: EmotionData.emotions[2], // 슬픔
      name: '파란 장미',
      flowerMeaning: '슬픔, 이루어질 수 없는 사랑',
      imageUrl: 'assets/images/flowers/blue_rose.png',
    ),

    // 분노 - 빨간 튤립
    EmotionFlower(
      emotion: EmotionData.emotions[3], // 분노
      name: '빨간 튤립',
      flowerMeaning: '열정, 불같은 사랑, 정열',
      imageUrl: 'assets/images/flowers/red_tulip.png',
    ),

    // 불안 - 수국
    EmotionFlower(
      emotion: EmotionData.emotions[4], // 불안
      name: '수국',
      flowerMeaning: '변덕, 변화무쌍, 진심',
      imageUrl: 'assets/images/flowers/hydrangea.png',
    ),

    // 사랑 - 장미
    EmotionFlower(
      emotion: EmotionData.emotions[5], // 사랑
      name: '장미',
      flowerMeaning: '사랑, 열정, 아름다움',
      imageUrl: 'assets/images/flowers/rose.png',
    ),

    // 지루함 - 민들레
    EmotionFlower(
      emotion: EmotionData.emotions[6], // 지루함
      name: '민들레',
      flowerMeaning: '희망, 행복, 새로운 시작',
      imageUrl: 'assets/images/flowers/dandelion.png',
    ),

    // 신남 - 개나리
    EmotionFlower(
      emotion: EmotionData.emotions[7], // 신남
      name: '개나리',
      flowerMeaning: '희망, 기대, 설렘',
      imageUrl: 'assets/images/flowers/forsythia.png',
    ),
  ];

  // 감정 ID로 꽃 찾기
  static EmotionFlower? findByEmotionId(String emotionId) {
    try {
      return flowers.firstWhere((flower) => flower.emotion.id == emotionId);
    } catch (e) {
      return null; // 해당 감정의 꽃이 없을 경우
    }
  }

  // 감정 객체로 꽃 찾기
  static EmotionFlower? findByEmotion(Emotion emotion) {
    return findByEmotionId(emotion.id);
  }
}
