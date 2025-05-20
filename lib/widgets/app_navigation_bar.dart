import 'package:flutter/material.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/utils/routes.dart';
import 'package:go_router/go_router.dart';

/// 앱 전체에서 일관된 하단 네비게이션 바를 제공하는 위젯입니다.
class AppNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AppNavigationBar({Key? key, required this.currentIndex})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home,
                label: '홈',
                index: 0,
                route: AppRoutes.home,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.collections_bookmark,
                label: '컬렉션',
                index: 1,
                route: AppRoutes.collection,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.history,
                label: '기록',
                index: 2,
                route: AppRoutes.history,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings,
                label: '설정',
                index: 3,
                route: AppRoutes.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 네비게이션 항목을 생성합니다.
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required String route,
  }) {
    final bool isSelected = index == currentIndex;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
