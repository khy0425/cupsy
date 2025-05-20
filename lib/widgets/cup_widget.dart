import 'package:flutter/material.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:cupsy/theme/app_theme.dart';

/// 컵 디자인을 표시하는 위젯
class CupWidget extends StatelessWidget {
  final CupDesign? cupDesign;
  final double scale;
  final bool showGlow;
  final bool showRarity;

  const CupWidget({
    Key? key,
    this.cupDesign,
    this.scale = 1.0,
    this.showGlow = false,
    this.showRarity = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컵 디자인이 없으면 기본 컵 사용
    final design = cupDesign ?? CupDesignsData.allDesigns.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 희귀도 표시
        if (showRarity)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: _buildRarityStars(design.rarity),
          ),

        // 컵 이미지
        Container(
          height: 180 * scale,
          width: 120 * scale,
          decoration: BoxDecoration(
            boxShadow:
                showGlow
                    ? [
                      BoxShadow(
                        color: _getRarityColor(design.rarity).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child:
              design.assetPath.isNotEmpty
                  ? Image.asset(
                    design.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => _buildErrorCup(),
                  )
                  : _buildErrorCup(),
        ),
      ],
    );
  }

  // 희귀도 별 표시
  Widget _buildRarityStars(CupRarity rarity) {
    final color = _getRarityColor(rarity);
    final stars = _getRarityStars(rarity);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stars,
        (index) => Icon(Icons.star, color: color, size: 14 * scale),
      ),
    );
  }

  // 희귀도별 색상
  Color _getRarityColor(CupRarity rarity) {
    switch (rarity) {
      case CupRarity.common:
        return Colors.grey;
      case CupRarity.uncommon:
        return Colors.green;
      case CupRarity.rare:
        return Colors.blue;
      case CupRarity.epic:
        return Colors.purple;
      case CupRarity.legendary:
        return Colors.orange;
    }
  }

  // 희귀도별 별 개수
  int _getRarityStars(CupRarity rarity) {
    switch (rarity) {
      case CupRarity.common:
        return 1;
      case CupRarity.uncommon:
        return 2;
      case CupRarity.rare:
        return 3;
      case CupRarity.epic:
        return 4;
      case CupRarity.legendary:
        return 5;
    }
  }

  // 이미지 로드 실패 시 대체 컵
  Widget _buildErrorCup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.local_cafe,
          color: Colors.grey.shade400,
          size: 48 * scale,
        ),
      ),
    );
  }
}
