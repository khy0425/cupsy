/// 상황 모델 클래스
class Situation {
  final String id; // 상황 ID (고유 식별자)
  final String name; // 상황 이름
  final String description; // 상황 설명
  final String icon; // 상황 아이콘 이름

  Situation({
    required this.id,
    required this.name,
    required this.description,
    this.icon = 'other',
  });

  // JSON에서 변환
  factory Situation.fromJson(Map<String, dynamic> json) {
    return Situation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'other',
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'icon': icon};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Situation && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
